import Combine
import Foundation
@preconcurrency import GameKit
import UIKit

private final class WeakSendableBox<Value: AnyObject>: @unchecked Sendable {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}

private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

struct GameKitPacket: Codable, Identifiable {
    let id: UUID
    let type: String
    let payload: Data
    let sentAt: Date

    init<Value: Encodable>(type: String, value: Value) throws {
        id = UUID()
        self.type = type
        payload = try JSONEncoder().encode(value)
        sentAt = Date()
    }

    func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        try JSONDecoder().decode(type, from: payload)
    }
}

struct GameKitReceivedPacket: Identifiable {
    let packet: GameKitPacket
    let sender: GKPlayer

    var id: UUID { packet.id }
}

@MainActor
final class GameKitManager: NSObject, ObservableObject {
    enum MatchState: String {
        case idle = "Not ready"
        case loadingActivity = "Loading room service"
        case ready = "Ready"
        case matchmaking = "Finding room members"
        case connected = "Connected"
        case failed = "Needs attention"
    }

    enum RoomRole: Equatable {
        case host
        case guest
    }

    static let shared = GameKitManager()
    static let activityDefinitionID = "boardgameroom"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var playerName = "Not signed in"
    @Published private(set) var matchState: MatchState = .idle
    @Published private(set) var players: [GKPlayer] = []
    @Published private(set) var receivedPackets: [GameKitReceivedPacket] = []
    @Published private(set) var statusMessage = "Game Center is not initialized."
    @Published private(set) var errorMessage: String?
    @Published private(set) var partyCode: String?
    @Published private(set) var partyURL: URL?
    @Published private(set) var roomRole: RoomRole?
    @Published var presentedViewController: UIViewController?

    var onPacketReceived: ((GameKitReceivedPacket) -> Void)?

    var isActivityReady: Bool { activityDefinition != nil }
    var hasActiveRoom: Bool { currentActivity != nil || match != nil }

    private var activityDefinition: GKGameActivityDefinition?
    private var currentActivity: GKGameActivity?
    private var match: GKMatch?
    private var didConfigureAuthentication = false
    private var isLoadingDefinition = false
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private override init() {
        super.init()
    }

    func authenticate() {
        guard !didConfigureAuthentication else {
            refreshAuthenticationState()
            return
        }

        didConfigureAuthentication = true
        statusMessage = "Signing in to Game Center…"
        GKLocalPlayer.local.register(self)

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                self.presentedViewController = viewController

                if let error {
                    self.setError("Game Center sign-in failed: \(error.localizedDescription)")
                }

                self.refreshAuthenticationState()
            }
        }
    }

    func createRoom() {
        guard canStartRoom(), let activityDefinition else { return }
        startActivity(
            definition: activityDefinition,
            code: Self.generatePartyCode(),
            role: .host
        )
    }

    func joinRoom(code: String) {
        guard canStartRoom(), let activityDefinition else { return }

        let normalizedCode = Self.normalizePartyCodeInput(code)
        guard GKGameActivity.isValidPartyCode(normalizedCode) else {
            setError("Enter a valid room code in the format ABC-DEF.")
            return
        }

        startActivity(definition: activityDefinition, code: normalizedCode, role: .guest)
    }

    func disconnect() {
        GKMatchmaker.shared().cancel()
        match?.disconnect()
        match?.delegate = nil
        currentActivity?.end()

        match = nil
        currentActivity = nil
        partyCode = nil
        partyURL = nil
        roomRole = nil
        players = []
        receivedPackets = []
        errorMessage = nil

        if isAuthenticated, activityDefinition != nil {
            matchState = .ready
            statusMessage = "Ready to create or join a room."
        } else {
            matchState = .idle
            statusMessage = "Sign in to Game Center to use rooms."
        }
    }

    func send<Value: Encodable>(
        _ value: Value,
        type: String,
        reliably: Bool = true
    ) {
        guard let match else {
            setError("There is no active Game Center match.")
            return
        }

        guard !players.isEmpty else {
            setError("Wait for at least one other player to connect.")
            return
        }

        do {
            let packet = try GameKitPacket(type: type, value: value)
            let data = try encoder.encode(packet)
            try match.sendData(
                toAllPlayers: data,
                with: reliably ? .reliable : .unreliable
            )
            errorMessage = nil
            statusMessage = "Message sent to \(players.count) player(s)."
        } catch {
            setError("Unable to send data: \(error.localizedDescription)")
        }
    }

    func clearReceivedPackets() {
        receivedPackets.removeAll()
    }

    func dismissPresentedController() {
        presentedViewController = nil
    }

    static func normalizePartyCodeInput(_ input: String) -> String {
        let characters = input
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(6)

        guard characters.count > 3 else {
            return String(characters)
        }

        let splitIndex = characters.index(characters.startIndex, offsetBy: 3)
        return "\(characters[..<splitIndex])-\(characters[splitIndex...])"
    }

    private static func generatePartyCode() -> String {
        let alphabet = GKGameActivity.validPartyCodeAlphabet

        if !alphabet.isEmpty {
            repeat {
                let characters = (0..<6).compactMap { _ in alphabet.randomElement() }
                let code = "\(characters[0...2].joined())-\(characters[3...5].joined())"
                if GKGameActivity.isValidPartyCode(code) {
                    return code
                }
            } while true
        }

        let digits = (0..<6).map { _ in String(Int.random(in: 0...9)) }
        return "\(digits[0...2].joined())-\(digits[3...5].joined())"
    }

    private func refreshAuthenticationState() {
        let localPlayer = GKLocalPlayer.local
        isAuthenticated = localPlayer.isAuthenticated

        if localPlayer.isAuthenticated {
            playerName = localPlayer.displayName
            errorMessage = nil
            loadActivityDefinition()
        } else {
            playerName = "Not signed in"
            activityDefinition = nil
            matchState = .idle
            statusMessage = "Sign in to Game Center to use multiplayer."
        }
    }

    private func loadActivityDefinition() {
        guard isAuthenticated, !isLoadingDefinition else { return }
        guard activityDefinition == nil else {
            matchState = .ready
            statusMessage = "Ready to create or join a room."
            return
        }

        isLoadingDefinition = true
        matchState = .loadingActivity
        statusMessage = "Loading the Game Center room configuration…"

        let owner = WeakSendableBox(self)

        GKGameActivityDefinition.loadGameActivityDefinitions(
            IDs: [Self.activityDefinitionID]
        ) { definitions, error in
            let result = UncheckedSendableBox(value: (definitions, error))

            Task { @MainActor in
                guard let self = owner.value else { return }
                let (definitions, error) = result.value
                self.isLoadingDefinition = false

                if let error {
                    self.setError("Unable to load \(Self.activityDefinitionID): \(error.localizedDescription)")
                    return
                }

                guard let definition = definitions?.first(where: {
                    $0.identifier == Self.activityDefinitionID && $0.supportsPartyCode
                }) else {
                    self.setError(
                        "Game Activity '\(Self.activityDefinitionID)' is missing or party codes are disabled in App Store Connect."
                    )
                    return
                }

                self.activityDefinition = definition
                self.matchState = .ready
                self.errorMessage = nil
                self.statusMessage = "Ready to create or join a room."
            }
        }
    }

    private func canStartRoom() -> Bool {
        guard isAuthenticated else {
            setError("Sign in to Game Center before using a room.")
            return false
        }

        guard !GKLocalPlayer.local.isMultiplayerGamingRestricted else {
            setError("Multiplayer games are restricted for this Game Center account.")
            return false
        }

        guard activityDefinition != nil else {
            setError("The Game Center room configuration is not ready.")
            return false
        }

        guard !hasActiveRoom else {
            setError("Leave the current room before starting another one.")
            return false
        }

        return true
    }

    private func startActivity(
        definition: GKGameActivityDefinition,
        code: String,
        role: RoomRole
    ) {
        do {
            let activity = try GKGameActivity.start(
                definition: definition,
                partyCode: code
            )

            beginMatchmaking(activity: activity, role: role)
        } catch {
            setError("Unable to start the room: \(error.localizedDescription)")
        }
    }

    private func beginMatchmaking(activity: GKGameActivity, role: RoomRole) {
        currentActivity?.end()
        currentActivity = activity
        partyCode = activity.partyCode
        partyURL = activity.partyURL
        roomRole = role
        matchState = .matchmaking
        errorMessage = nil
        statusMessage = role == .host
            ? "Room created. Share the code while Game Center waits for players."
            : "Joining room \(activity.partyCode ?? "")…"

        let owner = WeakSendableBox(self)
        let activityBox = WeakSendableBox(activity)

        activity.findMatch { match, error in
            let result = UncheckedSendableBox(value: (match, error))

            Task { @MainActor in
                guard let self = owner.value,
                      let activity = activityBox.value,
                      self.currentActivity === activity else { return }
                let (match, error) = result.value

                if let error {
                    self.setError("Matchmaking failed: \(error.localizedDescription)")
                    return
                }

                guard let match else {
                    self.setError("Game Center finished without creating a match.")
                    return
                }

                self.begin(match: match)
            }
        }
    }

    private func begin(match: GKMatch) {
        self.match?.delegate = nil
        self.match = match
        match.delegate = self
        players = match.players
        matchState = .connected
        presentedViewController = nil
        statusMessage = match.expectedPlayerCount == 0
            ? "Match ready with \(match.players.count + 1) players."
            : "Connected; waiting for \(match.expectedPlayerCount) more player(s)."
    }

    private func setError(_ message: String) {
        errorMessage = message
        statusMessage = message
        matchState = .failed
    }
}

extension GameKitManager: @preconcurrency GKMatchDelegate {
    func match(
        _ match: GKMatch,
        didReceive data: Data,
        fromRemotePlayer player: GKPlayer
    ) {
        do {
            let packet = try decoder.decode(GameKitPacket.self, from: data)
            let received = GameKitReceivedPacket(packet: packet, sender: player)
            receivedPackets.append(received)
            onPacketReceived?(received)
            statusMessage = "Received \(packet.type) from \(player.displayName)."
        } catch {
            setError("Ignored invalid data from \(player.displayName).")
        }
    }

    func match(
        _ match: GKMatch,
        player: GKPlayer,
        didChange state: GKPlayerConnectionState
    ) {
        players = match.players

        switch state {
        case .connected:
            matchState = .connected
            statusMessage = "\(player.displayName) connected."
        case .disconnected:
            statusMessage = "\(player.displayName) disconnected."
        case .unknown:
            statusMessage = "\(player.displayName) has an unknown connection state."
        @unknown default:
            statusMessage = "A player's connection state changed."
        }
    }

    func match(_ match: GKMatch, didFailWithError error: (any Error)?) {
        setError("Match error: \(error?.localizedDescription ?? "Unknown error")")
    }
}

extension GameKitManager: @preconcurrency GKLocalPlayerListener {
    func player(
        _ player: GKPlayer,
        wantsToPlay activity: GKGameActivity,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard activity.activityDefinition.identifier == Self.activityDefinitionID else {
            completionHandler(false)
            return
        }

        guard isAuthenticated, !hasActiveRoom else {
            completionHandler(false)
            return
        }

        beginMatchmaking(activity: activity, role: .guest)
        completionHandler(true)
    }
}
