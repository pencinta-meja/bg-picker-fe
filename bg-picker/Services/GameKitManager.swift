import Combine
import CryptoKit
import Foundation
@preconcurrency import GameKit
import Observation
import UIKit

private nonisolated final class WeakSendableBox<Value: AnyObject>: @unchecked Sendable {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}

private nonisolated struct UncheckedSendableBox<Value>: @unchecked Sendable {
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

private struct IncomingSourceTransfer {
    let manifest: RoomSourceManifest
    var chunks: [Int: Data] = [:]
}

@Observable
@MainActor
final class GameKitManager: NSObject, RoomSession {
    enum RoomRole: Equatable {
        case host
        case guest
    }

    static let shared = GameKitManager()
    static let activityDefinitionID = "boardgameroom"
    private static let sourceChunkSize = 24 * 1024

    private(set) var isAuthenticated = false
    private(set) var playerName = "Not signed in"
    private(set) var matchState: RoomMatchState = .idle
    private(set) var players: [GKPlayer] = []
    private(set) var receivedPackets: [GameKitReceivedPacket] = []
    private(set) var statusMessage = "Game Center is not initialized."
    private(set) var errorMessage: String?
    private(set) var partyCode: String?
    private(set) var partyURL: URL?
    private(set) var roomRole: RoomRole?
    var presentedViewController: UIViewController?

    @ObservationIgnored
    var onPacketReceived: ((GameKitReceivedPacket) -> Void)?

    var isActivityReady: Bool { activityDefinition != nil }
    var hasActiveRoom: Bool { currentActivity != nil || match != nil }
    var roomMemberCount: Int {
        observeSession()
        return sessionStore.localParticipantID == nil
            ? (hasActiveRoom ? players.count + 1 : 0)
            : sessionStore.roomMemberCount
    }

    // MARK: RoomSession domain state

    var gamePhase: RoomGamePhase { observeSession(); return sessionStore.phase }
    var isLocalHost: Bool { observeSession(); return sessionStore.isLocalHost }
    var localIsReady: Bool { observeSession(); return sessionStore.localIsReady }
    var canStartGame: Bool { observeSession(); return sessionStore.canStartGame }
    var canFinishSwiping: Bool { observeSession(); return sessionStore.canFinish }
    var participants: [RoomParticipant] { observeSession(); return sessionStore.connectedParticipants }
    var canonicalDeck: [BoardGameCard] { observeSession(); return sessionStore.cards }
    var localSwipeProgress: RoomSwipeProgress { observeSession(); return sessionStore.localProgress }
    var resultGroups: [RoomResultGroup] { observeSession(); return sessionStore.displayedResults }
    var finishedPlayerCount: Int { observeSession(); return sessionStore.finishedPlayerCount }
    var hasPendingResults: Bool { observeSession(); return sessionStore.hasPendingResults }
    var sessionError: String? { observeSession(); return sessionStore.roomError }

    private var activityDefinition: GKGameActivityDefinition?
    private var currentActivity: GKGameActivity?
    private var match: GKMatch?
    @ObservationIgnored private var didConfigureAuthentication = false
    @ObservationIgnored private var isLoadingDefinition = false
    @ObservationIgnored private let encoder = JSONEncoder()
    @ObservationIgnored private let decoder = JSONDecoder()
    @ObservationIgnored private let sessionStore = SessionGameStore.shared
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    @ObservationIgnored private var incomingTransfers: [String: IncomingSourceTransfer] = [:]
    @ObservationIgnored private var processedMessageIDs: Set<UUID> = []
    private var sessionObservationRevision = 0

    private override init() {
        super.init()
        sessionStore.$state
            .removeDuplicates()
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.sourceStateDidChange(state)
                }
            }
            .store(in: &cancellables)
        sessionStore.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.sessionObservationRevision &+= 1
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Authentication and room lifecycle

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
        guard canOpenRoom(), let activityDefinition else { return }
        let local = GKLocalPlayer.local
        sessionStore.beginHosting(localID: local.gamePlayerID, displayName: local.displayName)
        startActivity(
            definition: activityDefinition,
            code: Self.generatePartyCode(),
            role: .host
        )
    }

    func joinRoom(code: String) {
        guard canOpenRoom(), let activityDefinition else { return }
        let normalizedCode = PartyCode.normalize(code)
        guard GKGameActivity.isValidPartyCode(normalizedCode) else {
            setError("Enter a valid room code in the format ABC-DEF.")
            return
        }

        let local = GKLocalPlayer.local
        sessionStore.beginJoining(localID: local.gamePlayerID, displayName: local.displayName)
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
        incomingTransfers = [:]
        processedMessageIDs = []
        errorMessage = nil
        sessionStore.clear()

        if isAuthenticated, activityDefinition != nil {
            matchState = .ready
            statusMessage = "Ready to create or join a room."
        } else {
            matchState = .idle
            statusMessage = "Sign in to Game Center to use rooms."
        }
    }

    func dismissPresentedController() {
        presentedViewController = nil
    }

    // MARK: Shared game actions

    func setReady(categories: Set<BoardGameCategoryGroup>) {
        guard let payload = sessionStore.setLocalReady(categories: categories) else { return }
        broadcast(kind: .preference, value: payload)
        if isLocalHost { broadcastSnapshot() }
    }

    func setNotReady() {
        guard let payload = sessionStore.setLocalNotReady() else { return }
        broadcast(kind: .preference, value: payload)
        if isLocalHost { broadcastSnapshot() }
    }

    func startGame() {
        guard sessionStore.startGame(), let snapshot = sessionStore.makeSnapshot() else { return }
        broadcast(kind: .start, value: snapshot)
    }

    func recordDecision(gameID: String, accepted: Bool) {
        guard let payload = sessionStore.recordLocalDecision(gameID: gameID, accepted: accepted) else { return }
        broadcast(kind: .progress, value: payload)
    }

    func finishSwiping() {
        guard let payload = sessionStore.finishLocalSwipe() else { return }
        broadcast(kind: .progress, value: payload)
    }

    func refreshResults() {
        sessionStore.refreshResults()
    }

    // Kept as a manager-only utility for future non-session packets.
    func send<Value: Encodable>(_ value: Value, type: String, reliably: Bool = true) {
        guard let match else {
            setError("There is no active Game Center match.")
            return
        }
        do {
            let packet = try GameKitPacket(type: type, value: value)
            let data = try encoder.encode(packet)
            try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)
        } catch {
            setError("Unable to send data: \(error.localizedDescription)")
        }
    }

    func clearReceivedPackets() {
        receivedPackets.removeAll()
    }

    // MARK: Game activity setup

    private static func generatePartyCode() -> String {
        let alphabet = GKGameActivity.validPartyCodeAlphabet
        if !alphabet.isEmpty {
            repeat {
                let characters = (0..<6).compactMap { _ in alphabet.randomElement() }
                let code = "\(characters[0...2].joined())-\(characters[3...5].joined())"
                if GKGameActivity.isValidPartyCode(code) { return code }
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

        GKGameActivityDefinition.loadGameActivityDefinitions(IDs: [Self.activityDefinitionID]) { definitions, error in
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
                    self.setError("Game Activity '\(Self.activityDefinitionID)' is missing or party codes are disabled in App Store Connect.")
                    return
                }
                self.activityDefinition = definition
                self.matchState = .ready
                self.errorMessage = nil
                self.statusMessage = "Ready to create or join a room."
            }
        }
    }

    private func canOpenRoom() -> Bool {
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

    private func startActivity(definition: GKGameActivityDefinition, code: String, role: RoomRole) {
        do {
            let activity = try GKGameActivity.start(definition: definition, partyCode: code)
            beginMatchmaking(activity: activity, role: role)
        } catch {
            sessionStore.fail("Unable to start the room: \(error.localizedDescription)")
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
                    self.sessionStore.fail("Matchmaking failed: \(error.localizedDescription)")
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

        if isLocalHost {
            for player in match.players {
                acceptOrReject(player)
            }
        } else {
            sendHello()
        }
    }

    // MARK: Session transport

    private func sourceStateDidChange(_ state: SessionGameStore.LoadState) {
        guard isLocalHost else { return }
        switch state {
        case .loaded:
            guard prepareSourceChecksum() else { return }
            if let localID = sessionStore.localParticipantID {
                sessionStore.markSourceReady(playerID: localID)
            }
            for player in eligibleRemotePlayers {
                sendSource(to: player)
            }
            broadcastSnapshot()
        case .failed(let message):
            sessionStore.fail(message)
            broadcastSnapshot()
        case .idle, .loading:
            break
        }
    }

    private func prepareSourceChecksum() -> Bool {
        do {
            let data = try encoder.encode(sessionStore.games)
            sessionStore.setSourceChecksum(Self.checksum(data))
            return true
        } catch {
            sessionStore.fail("Unable to prepare the room's game list.")
            return false
        }
    }

    private func sendHello() {
        let local = GKLocalPlayer.local
        let hello = RoomHelloPayload(playerID: local.gamePlayerID, displayName: local.displayName)
        sendEnvelope(sessionID: nil, revision: 0, kind: .hello, value: hello, to: players)
    }

    private func acceptOrReject(_ player: GKPlayer) {
        if sessionStore.connectParticipant(id: player.gamePlayerID, displayName: player.displayName) {
            sendSnapshot(to: [player])
            sendSource(to: player)
            broadcastSnapshot()
        } else {
            let payload = RoomLockedPayload(message: "This room has already started. Only returning players can rejoin.")
            sendEnvelope(
                sessionID: sessionStore.sessionID,
                revision: sessionStore.snapshotRevision,
                kind: .locked,
                value: payload,
                to: [player]
            )
        }
    }

    private func sendSource(to player: GKPlayer) {
        guard sessionStore.state == .loaded,
              let sessionID = sessionStore.sessionID else { return }
        do {
            let data = try encoder.encode(sessionStore.games)
            let checksum = Self.checksum(data)
            sessionStore.setSourceChecksum(checksum)
            let chunks = Self.chunks(of: data, size: Self.sourceChunkSize)
            let transferID = UUID()
            let manifest = RoomSourceManifest(
                transferID: transferID,
                byteCount: data.count,
                chunkCount: chunks.count,
                checksum: checksum
            )
            sendEnvelope(
                sessionID: sessionID,
                revision: sessionStore.snapshotRevision,
                kind: .sourceManifest,
                value: manifest,
                to: [player]
            )
            for (index, chunk) in chunks.enumerated() {
                sendEnvelope(
                    sessionID: sessionID,
                    revision: sessionStore.snapshotRevision,
                    kind: .sourceChunk,
                    value: RoomSourceChunk(transferID: transferID, index: index, data: chunk),
                    to: [player]
                )
            }
        } catch {
            sessionStore.fail("Unable to share the room's game list.")
        }
    }

    private func sendSnapshot(to recipients: [GKPlayer]) {
        guard let snapshot = sessionStore.makeSnapshot() else { return }
        sendEnvelope(
            sessionID: snapshot.sessionID,
            revision: snapshot.revision,
            kind: .snapshot,
            value: snapshot,
            to: recipients
        )
    }

    private func broadcastSnapshot() {
        sendSnapshot(to: eligibleRemotePlayers)
    }

    private func broadcast<Value: Encodable>(kind: RoomWireKind, value: Value) {
        sendEnvelope(
            sessionID: sessionStore.sessionID,
            revision: sessionStore.snapshotRevision,
            kind: kind,
            value: value,
            to: eligibleRemotePlayers
        )
    }

    private var eligibleRemotePlayers: [GKPlayer] {
        guard sessionStore.phase == .started else { return players }
        return players.filter { sessionStore.frozenPlayerIDs.contains($0.gamePlayerID) }
    }

    private func sendEnvelope<Value: Encodable>(
        sessionID: UUID?,
        revision: Int,
        kind: RoomWireKind,
        value: Value,
        to recipients: [GKPlayer]
    ) {
        guard let match, !recipients.isEmpty else { return }
        do {
            let envelope = try RoomWireEnvelope(
                sessionID: sessionID,
                revision: revision,
                kind: kind,
                value: value
            )
            let data = try encoder.encode(envelope)
            try match.send(data, to: recipients, dataMode: .reliable)
        } catch {
            sessionStore.fail("Game Center could not synchronize the room: \(error.localizedDescription)")
        }
    }

    private func receiveRoomEnvelope(_ data: Data, from player: GKPlayer) -> Bool {
        guard let envelope = try? decoder.decode(RoomWireEnvelope.self, from: data) else { return false }
        guard envelope.version == RoomWireEnvelope.currentVersion else { return true }
        guard processedMessageIDs.insert(envelope.id).inserted else { return true }
        if processedMessageIDs.count > 512 {
            processedMessageIDs.removeAll(keepingCapacity: true)
            processedMessageIDs.insert(envelope.id)
        }

        let acceptsUnknownSession = envelope.kind == .hello
            || envelope.kind == .snapshot
            || envelope.kind == .locked
            || envelope.kind == .stateRequest
        if !acceptsUnknownSession,
           let currentSessionID = sessionStore.sessionID,
           envelope.sessionID != currentSessionID {
            return true
        }

        handle(envelope, from: player)
        return true
    }

    private func handle(_ envelope: RoomWireEnvelope, from player: GKPlayer) {
        let senderID = player.gamePlayerID
        switch envelope.kind {
        case .hello:
            guard isLocalHost,
                  let hello = try? envelope.decode(RoomHelloPayload.self),
                  hello.playerID == senderID else { return }
            acceptOrReject(player)

        case .snapshot:
            guard let snapshot = try? envelope.decode(RoomWireSnapshot.self),
                  snapshot.authorityID == senderID,
                  envelope.sessionID == snapshot.sessionID else { return }
            sessionStore.configureFromSnapshot(snapshot)

        case .sourceManifest:
            guard let manifest = try? envelope.decode(RoomSourceManifest.self),
                  sessionStore.authorityID == senderID,
                  manifest.chunkCount > 0,
                  manifest.byteCount >= 0 else { return }
            incomingTransfers[transferKey(senderID: senderID, transferID: manifest.transferID)] =
                IncomingSourceTransfer(manifest: manifest)

        case .sourceChunk:
            guard sessionStore.authorityID == senderID,
                  let chunk = try? envelope.decode(RoomSourceChunk.self) else { return }
            receive(chunk: chunk, from: player)

        case .sourceReady:
            guard isLocalHost,
                  let ready = try? envelope.decode(RoomSourceReady.self),
                  ready.checksum == sessionStore.sourceChecksum else { return }
            sessionStore.markSourceReady(playerID: senderID)
            broadcastSnapshot()

        case .preference:
            guard let preference = try? envelope.decode(RoomWirePreference.self) else { return }
            sessionStore.mergePreference(preference, senderID: senderID)
            if isLocalHost { broadcastSnapshot() }

        case .start:
            guard let snapshot = try? envelope.decode(RoomWireSnapshot.self),
                  snapshot.authorityID == senderID,
                  envelope.sessionID == snapshot.sessionID,
                  snapshot.phase == .started else { return }
            sessionStore.configureFromSnapshot(snapshot)

        case .progress:
            guard let progress = try? envelope.decode(RoomWireProgress.self) else { return }
            sessionStore.mergeProgress(progress, senderID: senderID)

        case .locked:
            guard let payload = try? envelope.decode(RoomLockedPayload.self) else { return }
            sessionStore.lockOut(payload.message)

        case .stateRequest:
            guard isLocalHost else { return }
            acceptOrReject(player)
        }
    }

    private func receive(chunk: RoomSourceChunk, from player: GKPlayer) {
        let key = transferKey(senderID: player.gamePlayerID, transferID: chunk.transferID)
        guard var transfer = incomingTransfers[key],
              chunk.index >= 0,
              chunk.index < transfer.manifest.chunkCount else { return }
        transfer.chunks[chunk.index] = chunk.data
        incomingTransfers[key] = transfer

        guard transfer.chunks.count == transfer.manifest.chunkCount else { return }
        var data = Data()
        for index in 0..<transfer.manifest.chunkCount {
            guard let part = transfer.chunks[index] else { return }
            data.append(part)
        }
        incomingTransfers.removeValue(forKey: key)

        guard data.count == transfer.manifest.byteCount,
              Self.checksum(data) == transfer.manifest.checksum,
              let games = try? decoder.decode([BGGItem].self, from: data) else {
            requestState(from: player)
            return
        }

        sessionStore.applyReplicatedSource(games, checksum: transfer.manifest.checksum)
        let ready = RoomSourceReady(checksum: transfer.manifest.checksum)
        sendEnvelope(
            sessionID: sessionStore.sessionID,
            revision: sessionStore.snapshotRevision,
            kind: .sourceReady,
            value: ready,
            to: [player]
        )
    }

    private func requestState(from player: GKPlayer) {
        sendEnvelope(
            sessionID: sessionStore.sessionID,
            revision: sessionStore.snapshotRevision,
            kind: .stateRequest,
            value: RoomHelloPayload(
                playerID: GKLocalPlayer.local.gamePlayerID,
                displayName: GKLocalPlayer.local.displayName
            ),
            to: [player]
        )
    }

    private func transferKey(senderID: String, transferID: UUID) -> String {
        "\(senderID)|\(transferID.uuidString)"
    }

    private static func checksum(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func chunks(of data: Data, size: Int) -> [Data] {
        guard !data.isEmpty else { return [Data()] }
        return stride(from: 0, to: data.count, by: size).map { offset in
            data.subdata(in: offset..<min(offset + size, data.count))
        }
    }

    private func observeSession() {
        _ = sessionObservationRevision
    }

    private func setError(_ message: String) {
        errorMessage = message
        statusMessage = message
        matchState = .failed
    }
}

extension GameKitManager: @preconcurrency GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if receiveRoomEnvelope(data, from: player) { return }
        do {
            let packet = try decoder.decode(GameKitPacket.self, from: data)
            let received = GameKitReceivedPacket(packet: packet, sender: player)
            receivedPackets.append(received)
            onPacketReceived?(received)
        } catch {
            statusMessage = "Ignored invalid data from \(player.displayName)."
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        players = match.players
        switch state {
        case .connected:
            matchState = .connected
            statusMessage = "\(player.displayName) connected."
            if isLocalHost {
                acceptOrReject(player)
            } else {
                sendHello()
            }
        case .disconnected:
            statusMessage = "\(player.displayName) disconnected."
            sessionStore.disconnectParticipant(id: player.gamePlayerID)
            if isLocalHost {
                if sessionStore.state == .loaded {
                    for remote in eligibleRemotePlayers { sendSource(to: remote) }
                }
                broadcastSnapshot()
            }
        case .unknown:
            statusMessage = "\(player.displayName) has an unknown connection state."
        @unknown default:
            statusMessage = "A player's connection state changed."
        }
    }

    func match(_ match: GKMatch, didFailWithError error: (any Error)?) {
        let message = "Match error: \(error?.localizedDescription ?? "Unknown error")"
        sessionStore.fail(message)
        setError(message)
    }
}

extension GameKitManager: @preconcurrency GKLocalPlayerListener {
    func player(
        _ player: GKPlayer,
        wantsToPlay activity: GKGameActivity,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard activity.activityDefinition.identifier == Self.activityDefinitionID,
              isAuthenticated,
              !hasActiveRoom else {
            completionHandler(false)
            return
        }

        let local = GKLocalPlayer.local
        sessionStore.beginJoining(localID: local.gamePlayerID, displayName: local.displayName)
        beginMatchmaking(activity: activity, role: .guest)
        completionHandler(true)
    }
}
