//
//  PreviewRoomSession.swift
//  bg-picker
//
//  DEBUG-only `RoomSession` conformer for Xcode previews.
//
//  The real conformer is `GameKitManager.shared`, which cannot authenticate in a preview —
//  and cannot authenticate at all for a contributor who does not own the App ID. Previews
//  against it show permanently disabled buttons, no QR code, and "0 People Joined".
//
//  This poses the same screens in any state without touching Game Center. It is a preview
//  fixture, not a simulator: it never proves matchmaking works.
//

#if DEBUG
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class PreviewRoomSession: RoomSession {
    var isAuthenticated: Bool
    var isActivityReady: Bool
    var hasActiveRoom: Bool
    var matchState: RoomMatchState
    var statusMessage: String
    var errorMessage: String?
    var partyCode: String?
    var partyURL: URL?
    var roomMemberCount: Int
    var presentedViewController: UIViewController?
    var gamePhase: RoomGamePhase
    var isLocalHost: Bool
    var localIsReady: Bool
    var participants: [RoomParticipant]
    var canonicalDeck: [BoardGameCard]
    var localSwipeProgress: RoomSwipeProgress
    var resultGroups: [RoomResultGroup]
    var finishedPlayerCount: Int
    var hasPendingResults: Bool
    var sessionError: String?
    private var progressByPlayer: [String: RoomSwipeProgress]

    var canStartGame: Bool {
        let connected = participants.filter(\.isConnected)
        return isLocalHost
            && gamePhase != .started
            && RoomSessionReducer.canStart(
                connectedParticipants: connected,
                sourceReadyPlayerIDs: Set(connected.map(\.id)),
                hasLoadedSource: !canonicalDeck.isEmpty,
                hasMatchingGames: !canonicalDeck.isEmpty
            )
    }

    var canFinishSwiping: Bool {
        gamePhase == .started
            && !localSwipeProgress.isFinished
            && !canonicalDeck.isEmpty
            && localSwipeProgress.decisions.count == canonicalDeck.count
    }

    init(
        isAuthenticated: Bool = true,
        isActivityReady: Bool = true,
        hasActiveRoom: Bool = false,
        matchState: RoomMatchState = .ready,
        statusMessage: String = "Ready to create or join a room.",
        errorMessage: String? = nil,
        partyCode: String? = nil,
        partyURL: URL? = nil,
        roomMemberCount: Int = 0,
        gamePhase: RoomGamePhase = .idle,
        isLocalHost: Bool = false,
        localIsReady: Bool = false,
        participants: [RoomParticipant] = [],
        canonicalDeck: [BoardGameCard] = [],
        localSwipeProgress: RoomSwipeProgress = RoomSwipeProgress(),
        resultGroups: [RoomResultGroup] = [],
        finishedPlayerCount: Int = 0,
        hasPendingResults: Bool = false,
        sessionError: String? = nil,
        progressByPlayer: [String: RoomSwipeProgress] = [:]
    ) {
        self.isAuthenticated = isAuthenticated
        self.isActivityReady = isActivityReady
        self.hasActiveRoom = hasActiveRoom
        self.matchState = matchState
        self.statusMessage = statusMessage
        self.errorMessage = errorMessage
        self.partyCode = partyCode
        self.partyURL = partyURL
        self.roomMemberCount = roomMemberCount
        self.gamePhase = gamePhase
        self.isLocalHost = isLocalHost
        self.localIsReady = localIsReady
        self.participants = participants
        self.canonicalDeck = canonicalDeck
        self.localSwipeProgress = localSwipeProgress
        self.resultGroups = resultGroups
        self.finishedPlayerCount = finishedPlayerCount
        self.hasPendingResults = hasPendingResults
        self.sessionError = sessionError
        self.progressByPlayer = progressByPlayer
    }

    // The actions move state so previews stay interactive rather than frozen.

    func authenticate() {
        isAuthenticated = true
        isActivityReady = true
        matchState = .ready
        errorMessage = nil
        statusMessage = "Ready to create or join a room."
    }

    func createRoom() {
        open(
            code: "ABC-DEF",
            status: "Room created. Share the code while Game Center waits for players."
        )
    }

    func joinRoom(code: String) {
        let normalized = PartyCode.normalize(code)
        open(code: normalized, status: "Joining room \(normalized)…")
    }

    func disconnect() {
        hasActiveRoom = false
        partyCode = nil
        partyURL = nil
        roomMemberCount = 0
        errorMessage = nil
        matchState = .ready
        statusMessage = "Ready to create or join a room."
        gamePhase = .idle
        participants = []
        canonicalDeck = []
        localSwipeProgress = RoomSwipeProgress()
        resultGroups = []
        finishedPlayerCount = 0
        hasPendingResults = false
        sessionError = nil
        progressByPlayer = [:]
    }

    func dismissPresentedController() {
        presentedViewController = nil
    }

    func setReady(categories: Set<BoardGameCategoryGroup>) {
        localIsReady = true
        updateLocalParticipant(ready: true)
        let connected = participants.filter(\.isConnected)
        gamePhase = RoomSessionReducer.preStartPhase(
            connectedParticipants: connected,
            sourceReadyPlayerIDs: Set(connected.map(\.id)),
            hasLoadedSource: !canonicalDeck.isEmpty,
            hasMatchingGames: !canonicalDeck.isEmpty
        )
    }

    func setNotReady() {
        guard gamePhase != .started else { return }
        localIsReady = false
        updateLocalParticipant(ready: false)
        gamePhase = .waitingForReady
    }

    func startGame() {
        guard canStartGame else { return }
        gamePhase = .started
    }

    func recordDecision(gameID: String, accepted: Bool) {
        guard gamePhase == .started,
              !localSwipeProgress.isFinished,
              localSwipeProgress.decisions[gameID] == nil else { return }
        localSwipeProgress.revision += 1
        localSwipeProgress.decisions[gameID] = accepted ? .accepted : .rejected
        progressByPlayer["preview-local"] = localSwipeProgress
    }

    func finishSwiping() {
        guard canFinishSwiping else { return }
        localSwipeProgress.revision += 1
        localSwipeProgress.isFinished = true
        progressByPlayer["preview-local"] = localSwipeProgress
        finishedPlayerCount = max(finishedPlayerCount, 1)
        hasPendingResults = true
    }

    func refreshResults() {
        progressByPlayer["preview-local"] = localSwipeProgress
        resultGroups = RoomSessionReducer.resultGroups(
            cards: canonicalDeck,
            progressByPlayer: progressByPlayer
        )
        finishedPlayerCount = progressByPlayer.values.filter(\.isFinished).count
        hasPendingResults = false
    }

    private func open(code: String, status: String) {
        partyCode = code
        partyURL = URL(string: "https://gamecenter.apple.com/party/\(code)")
        hasActiveRoom = true
        roomMemberCount = 1
        matchState = .matchmaking
        errorMessage = nil
        statusMessage = status
        gamePhase = .waitingForPlayers
        isLocalHost = status.hasPrefix("Room created")
        participants = [
            RoomParticipant(
                id: "preview-local",
                displayName: "You",
                isConnected: true,
                isReady: false
            )
        ]
    }

    private func updateLocalParticipant(ready: Bool) {
        if let index = participants.firstIndex(where: { $0.id == "preview-local" }) {
            participants[index].isReady = ready
        }
    }
}

// The states the screens actually branch on.
extension PreviewRoomSession {
    static var signedOut: PreviewRoomSession {
        PreviewRoomSession(
            isAuthenticated: false,
            isActivityReady: false,
            matchState: .idle,
            statusMessage: "Sign in to Game Center to use multiplayer."
        )
    }

    static var loadingActivity: PreviewRoomSession {
        PreviewRoomSession(
            isActivityReady: false,
            matchState: .loadingActivity,
            statusMessage: "Loading the Game Center room configuration…"
        )
    }

    static var ready: PreviewRoomSession {
        PreviewRoomSession()
    }

    static var waitingForPlayers: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .matchmaking,
            statusMessage: "Room created. Share the code while Game Center waits for players.",
            partyCode: "ABC-DEF",
            partyURL: URL(string: "https://gamecenter.apple.com/party/ABC-DEF"),
            roomMemberCount: 3,
            gamePhase: .waitingForReady,
            isLocalHost: true,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: false),
                RoomParticipant(id: "preview-friend-1", displayName: "Ari", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend-2", displayName: "Maya", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck
        )
    }

    static var hostReadyToStart: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Everyone is ready.",
            partyCode: "ABC-DEF",
            partyURL: URL(string: "https://gamecenter.apple.com/party/ABC-DEF"),
            roomMemberCount: 2,
            gamePhase: .readyToStart,
            isLocalHost: true,
            localIsReady: true,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend", displayName: "Ari", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck
        )
    }

    static var sourceSynchronizing: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Receiving the host’s geeklist…",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .synchronizing,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: false),
                RoomParticipant(id: "preview-host", displayName: "Host", isConnected: true, isReady: false)
            ]
        )
    }

    static var categoryUnionFiltered: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "The category union produced one game.",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .readyToStart,
            isLocalHost: true,
            localIsReady: true,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend", displayName: "Ari", isConnected: true, isReady: true)
            ],
            canonicalDeck: Array(previewDeck.prefix(1))
        )
    }

    static var started: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Game in progress.",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .started,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend", displayName: "Ari", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck
        )
    }

    static var startedWithPartialProgress: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Game in progress.",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .started,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend", displayName: "Ari", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck,
            localSwipeProgress: RoomSwipeProgress(
                revision: 1,
                decisions: ["preview-1": .accepted],
                isFinished: false
            )
        )
    }

    static var knownPlayerReconnected: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Your previous swipe progress was restored.",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .started,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-authority", displayName: "Maya", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck,
            localSwipeProgress: RoomSwipeProgress(
                revision: 1,
                decisions: ["preview-1": .rejected],
                isFinished: false
            )
        )
    }

    static var finishedSubmissionLocked: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "Your submitted choices are final.",
            partyCode: "ABC-DEF",
            roomMemberCount: 2,
            gamePhase: .started,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend", displayName: "Ari", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck,
            localSwipeProgress: RoomSwipeProgress(
                revision: 3,
                decisions: ["preview-1": .accepted, "preview-2": .rejected],
                isFinished: true
            ),
            finishedPlayerCount: 1
        )
    }

    static var partialResultsPending: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "A new player finished.",
            partyCode: "ABC-DEF",
            roomMemberCount: 3,
            gamePhase: .started,
            participants: [
                RoomParticipant(id: "preview-local", displayName: "You", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend-1", displayName: "Ari", isConnected: true, isReady: true),
                RoomParticipant(id: "preview-friend-2", displayName: "Maya", isConnected: true, isReady: true)
            ],
            canonicalDeck: previewDeck,
            localSwipeProgress: RoomSwipeProgress(
                revision: 3,
                decisions: ["preview-1": .accepted, "preview-2": .rejected],
                isFinished: true
            ),
            resultGroups: [
                RoomResultGroup(voteCount: 1, finishedPlayerCount: 1, cards: [previewDeck[0]])
            ],
            finishedPlayerCount: 2,
            hasPendingResults: true,
            progressByPlayer: [
                "preview-local": RoomSwipeProgress(
                    revision: 3,
                    decisions: ["preview-1": .accepted, "preview-2": .rejected],
                    isFinished: true
                ),
                "preview-friend-1": RoomSwipeProgress(
                    revision: 3,
                    decisions: ["preview-1": .accepted, "preview-2": .accepted],
                    isFinished: true
                )
            ]
        )
    }

    static var lateJoinLocked: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .connected,
            statusMessage: "This room has already started.",
            partyCode: "ABC-DEF",
            roomMemberCount: 1,
            gamePhase: .lockedOut,
            sessionError: "This room has already started. Only returning players can rejoin."
        )
    }

    static func failed(
        _ message: String = "Game Activity 'boardgameroom' is missing or party codes are disabled in App Store Connect."
    ) -> PreviewRoomSession {
        PreviewRoomSession(
            isActivityReady: false,
            matchState: .failed,
            statusMessage: message,
            errorMessage: message
        )
    }

    static var transferFailure: PreviewRoomSession {
        failed("The geeklist transfer failed its checksum. Requesting it again…")
    }

    static var roomFailure: PreviewRoomSession {
        PreviewRoomSession(
            hasActiveRoom: true,
            matchState: .failed,
            statusMessage: "The room ended because no synchronized player remains.",
            partyCode: "ABC-DEF",
            roomMemberCount: 0,
            gamePhase: .failed,
            sessionError: "The room ended because no synchronized player remains."
        )
    }

    static var gameKitFailure: PreviewRoomSession {
        failed("Game Center could not synchronize the room.")
    }
}

private extension PreviewRoomSession {
    static var previewDeck: [BoardGameCard] {
        [
            BoardGameCard(
                id: "preview-1",
                title: "Preview Adventure",
                description: "A deterministic preview card.",
                thumbnailURL: nil,
                gameplayImageURL: nil,
                thumbnailLocalImage: nil,
                gameplayLocalImage: nil,
                categoriesText: "Adventure",
                playTimeText: "30 min",
                playersText: "2–4 players",
                complexityText: "2.0 / 5",
                ratingText: "7.5 / 10"
            ),
            BoardGameCard(
                id: "preview-2",
                title: "Preview Strategy",
                description: "A second card for swipe and result previews.",
                thumbnailURL: nil,
                gameplayImageURL: nil,
                thumbnailLocalImage: nil,
                gameplayLocalImage: nil,
                categoriesText: "Strategy",
                playTimeText: "45 min",
                playersText: "2–6 players",
                complexityText: "3.0 / 5",
                ratingText: "8.0 / 10"
            )
        ]
    }
}
#endif
