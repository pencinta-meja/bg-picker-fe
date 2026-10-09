//
//  SessionGameStore.swift
//  bg-picker
//
//  Transient source of truth for one room. Shared state lives here rather than in
//  a screen so reconnects and navigation never discard the active session.
//

import Combine
import Foundation

@MainActor
final class SessionGameStore: ObservableObject {
    private static let noMatchingGamesMessage =
        "No games match the selected category union. Edit the preferences and try again."

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    static let shared = SessionGameStore()

    init() {}

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var phase: RoomGamePhase = .idle
    @Published private(set) var games: [BGGItem] = []
    @Published private(set) var sourceCards: [BoardGameCard] = []
    @Published private(set) var cards: [BoardGameCard] = []
    @Published private(set) var participants: [String: RoomParticipant] = [:]
    @Published private(set) var preferences: [String: Set<BoardGameCategoryGroup>] = [:]
    @Published private(set) var progressByPlayer: [String: RoomSwipeProgress] = [:]
    @Published private(set) var displayedResults: [RoomResultGroup] = []
    @Published private(set) var hasPendingResults = false
    @Published private(set) var roomError: String?

    private(set) var sessionID: UUID?
    private(set) var authorityID: String?
    private(set) var localParticipantID: String?
    private(set) var frozenPlayerIDs: Set<String> = []
    private(set) var sourceChecksum: String?
    private(set) var snapshotRevision = 0
    private(set) var canonicalGameIDs: [String] = []
    private(set) var sourceReadyPlayerIDs: Set<String> = []

    private var preferenceRevisions: [String: Int] = [:]
    private var loadTask: Task<Void, Never>?

    var isLoading: Bool { state == .loading }
    var hasGames: Bool { !sourceCards.isEmpty }
    var isLocalHost: Bool { localParticipantID != nil && localParticipantID == authorityID }
    var localIsReady: Bool {
        guard let localParticipantID else { return false }
        return participants[localParticipantID]?.isReady == true
    }
    var localProgress: RoomSwipeProgress {
        guard let localParticipantID else { return RoomSwipeProgress() }
        return progressByPlayer[localParticipantID] ?? RoomSwipeProgress()
    }
    var connectedParticipants: [RoomParticipant] {
        participants.values.filter(\.isConnected).sorted { $0.id < $1.id }
    }
    var roomMemberCount: Int { connectedParticipants.count }
    var finishedPlayerCount: Int { progressByPlayer.values.filter(\.isFinished).count }
    var canFinish: Bool {
        phase == .started
            && !localProgress.isFinished
            && localProgress.decisions.count == cards.count
            && !cards.isEmpty
    }
    var canStartGame: Bool {
        isLocalHost && RoomSessionReducer.canStart(
            connectedParticipants: connectedParticipants,
            sourceReadyPlayerIDs: sourceReadyPlayerIDs,
            hasLoadedSource: state == .loaded,
            hasMatchingGames: !filteredGamesForConnectedPlayers().isEmpty
        )
    }

    func load(geeklistID: String) {
        loadTask?.cancel()
        applySourceState(.loading, games: [])

        loadTask = Task { [weak self] in
            do {
                let games = try await BGGService.shared.fetchGeeklistGames(id: geeklistID)
                guard !Task.isCancelled else { return }
                self?.applySourceState(.loaded, games: games)
                if let localID = self?.localParticipantID {
                    self?.sourceReadyPlayerIDs.insert(localID)
                }
                self?.refreshPreStartPhase()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.applySourceState(.failed(error.localizedDescription), games: [])
                self?.fail("Unable to load the geeklist: \(error.localizedDescription)")
            }
        }
    }

    @discardableResult
    func load(fromInput input: String) -> Bool {
        guard let id = BGGService.geeklistID(from: input) else { return false }
        load(geeklistID: id)
        return true
    }

    func beginHosting(localID: String, displayName: String) {
        resetRoomState(keepingSource: true)
        sessionID = UUID()
        authorityID = localID
        localParticipantID = localID
        participants[localID] = RoomParticipant(
            id: localID,
            displayName: displayName,
            isConnected: true,
            isReady: false
        )
        if state == .loaded {
            sourceReadyPlayerIDs.insert(localID)
        }
        phase = .waitingForPlayers
        snapshotRevision = 1
    }

    func beginJoining(localID: String, displayName: String) {
        clear()
        localParticipantID = localID
        participants[localID] = RoomParticipant(
            id: localID,
            displayName: displayName,
            isConnected: true,
            isReady: false
        )
        phase = .synchronizing
    }

    func configureFromSnapshot(_ snapshot: RoomWireSnapshot) {
        guard sessionID == nil || sessionID == snapshot.sessionID else { return }
        guard snapshot.revision >= snapshotRevision else { return }

        let currentParticipants = participants
        let currentPreferences = preferences
        let currentPreferenceRevisions = preferenceRevisions
        let currentProgress = progressByPlayer

        sessionID = snapshot.sessionID
        authorityID = snapshot.authorityID
        snapshotRevision = snapshot.revision
        phase = snapshot.phase
        participants = Dictionary(uniqueKeysWithValues: snapshot.participants.map {
            ($0.id, RoomParticipant(
                id: $0.id,
                displayName: $0.displayName,
                isConnected: $0.isConnected,
                isReady: $0.isReady
            ))
        })
        preferences = currentPreferences
        preferenceRevisions = currentPreferenceRevisions
        for preference in snapshot.preferences {
            let currentRevision = currentPreferenceRevisions[preference.playerID, default: -1]
            if currentRevision > preference.revision {
                preferenceRevisions[preference.playerID] = currentRevision
                preferences[preference.playerID] = currentPreferences[preference.playerID] ?? []
                if let current = currentParticipants[preference.playerID] {
                    participants[preference.playerID]?.isReady = current.isReady
                }
            } else {
                preferenceRevisions[preference.playerID] = preference.revision
                preferences[preference.playerID] = Set(
                    preference.categories.compactMap(BoardGameCategoryGroup.init(rawValue:))
                )
                participants[preference.playerID]?.isReady = preference.isReady
            }
        }
        let snapshotPreferenceIDs = Set(snapshot.preferences.map(\.playerID))
        for playerID in currentPreferenceRevisions.keys where !snapshotPreferenceIDs.contains(playerID) {
            if let current = currentParticipants[playerID] {
                participants[playerID]?.isReady = current.isReady
            }
        }

        var mergedProgress = currentProgress
        for payload in snapshot.progress {
            mergedProgress[payload.playerID] = RoomSessionReducer.merge(
                incoming: payload.progress,
                into: currentProgress[payload.playerID]
            )
        }
        progressByPlayer = mergedProgress
        frozenPlayerIDs = Set(snapshot.frozenPlayerIDs)
        canonicalGameIDs = snapshot.canonicalGameIDs
        sourceChecksum = snapshot.sourceChecksum
        rebuildCanonicalCards()
        updateLiveResults()
    }

    func makeSnapshot() -> RoomWireSnapshot? {
        guard let sessionID, let authorityID else { return nil }
        return RoomWireSnapshot(
            sessionID: sessionID,
            authorityID: authorityID,
            revision: snapshotRevision,
            phase: phase,
            participants: participants.values.sorted { $0.id < $1.id }.map {
                RoomWireParticipant(
                    id: $0.id,
                    displayName: $0.displayName,
                    isConnected: $0.isConnected,
                    isReady: $0.isReady
                )
            },
            preferences: preferences.keys.sorted().map { playerID in
                RoomWirePreference(
                    playerID: playerID,
                    revision: preferenceRevisions[playerID, default: 0],
                    categories: (preferences[playerID] ?? []).map(\.rawValue).sorted(),
                    isReady: participants[playerID]?.isReady == true
                )
            },
            progress: progressByPlayer.keys.sorted().map {
                RoomWireProgress(playerID: $0, progress: progressByPlayer[$0] ?? RoomSwipeProgress())
            },
            frozenPlayerIDs: frozenPlayerIDs.sorted(),
            canonicalGameIDs: canonicalGameIDs,
            sourceChecksum: sourceChecksum
        )
    }

    func applyReplicatedSource(_ games: [BGGItem], checksum: String) {
        sourceChecksum = checksum
        applySourceState(.loaded, games: games)
        if let localParticipantID {
            sourceReadyPlayerIDs.insert(localParticipantID)
        }
        rebuildCanonicalCards()
        updateLiveResults()
        refreshPreStartPhase()
    }

    func setSourceChecksum(_ checksum: String) {
        sourceChecksum = checksum
    }

    func markSourceReady(playerID: String) {
        sourceReadyPlayerIDs.insert(playerID)
        refreshPreStartPhase()
    }

    func connectParticipant(id: String, displayName: String) -> Bool {
        if phase == .started, !frozenPlayerIDs.contains(id) {
            return false
        }

        let wasConnected = participants[id]?.isConnected == true
        var participant = participants[id] ?? RoomParticipant(
            id: id,
            displayName: displayName,
            isConnected: true,
            isReady: false
        )
        participant.displayName = displayName
        participant.isConnected = true
        // GameKit can report the same connection more than once. Only a genuinely new
        // connection/reconnection invalidates pre-start readiness; a duplicate callback
        // must not make an already-ready player silently unready.
        if phase != .started, !wasConnected {
            participant.isReady = false
        }
        participants[id] = participant
        bumpSnapshot()
        refreshPreStartPhase()
        return true
    }

    func disconnectParticipant(id: String) {
        guard var participant = participants[id] else { return }
        participant.isConnected = false
        if phase != .started {
            participant.isReady = false
            sourceReadyPlayerIDs.remove(id)
        }
        participants[id] = participant

        if authorityID == id {
            let eligible = phase == .started ? frozenPlayerIDs : Set(participants.keys)
            authorityID = RoomSessionReducer.electedAuthority(
                participants: participants,
                eligiblePlayerIDs: eligible
            )
            if authorityID == nil {
                fail("The room ended because no synchronized player remains.")
            }
        }

        bumpSnapshot()
        refreshPreStartPhase()
    }

    @discardableResult
    func setLocalReady(categories: Set<BoardGameCategoryGroup>) -> RoomWirePreference? {
        guard phase != .started, let localParticipantID else { return nil }
        let revision = preferenceRevisions[localParticipantID, default: 0] + 1
        preferenceRevisions[localParticipantID] = revision
        preferences[localParticipantID] = categories
        participants[localParticipantID]?.isReady = true
        bumpSnapshot()
        refreshPreStartPhase()
        return preferencePayload(for: localParticipantID)
    }

    @discardableResult
    func setLocalNotReady() -> RoomWirePreference? {
        guard phase != .started, let localParticipantID else { return nil }
        let revision = preferenceRevisions[localParticipantID, default: 0] + 1
        preferenceRevisions[localParticipantID] = revision
        participants[localParticipantID]?.isReady = false
        bumpSnapshot()
        refreshPreStartPhase()
        return preferencePayload(for: localParticipantID)
    }

    func mergePreference(_ payload: RoomWirePreference, senderID: String) {
        guard payload.playerID == senderID, phase != .started else { return }
        guard payload.revision > preferenceRevisions[senderID, default: -1] else { return }
        preferenceRevisions[senderID] = payload.revision
        preferences[senderID] = Set(payload.categories.compactMap(BoardGameCategoryGroup.init(rawValue:)))
        participants[senderID]?.isReady = payload.isReady
        bumpSnapshot()
        refreshPreStartPhase()
    }

    @discardableResult
    func startGame() -> Bool {
        guard canStartGame else { return false }
        let filtered = filteredGamesForConnectedPlayers()
        guard !filtered.isEmpty else {
            roomError = Self.noMatchingGamesMessage
            return false
        }

        frozenPlayerIDs = Set(connectedParticipants.map(\.id))
        canonicalGameIDs = filtered.map(\.id).shuffled()
        phase = .started
        roomError = nil
        rebuildCanonicalCards()
        bumpSnapshot()
        return true
    }

    @discardableResult
    func recordLocalDecision(gameID: String, accepted: Bool) -> RoomWireProgress? {
        guard phase == .started,
              let localParticipantID,
              frozenPlayerIDs.contains(localParticipantID),
              canonicalGameIDs.contains(gameID) else { return nil }

        var progress = progressByPlayer[localParticipantID] ?? RoomSwipeProgress()
        guard !progress.isFinished, progress.decisions[gameID] == nil else { return nil }
        progress.revision += 1
        progress.decisions[gameID] = accepted ? .accepted : .rejected
        progressByPlayer[localParticipantID] = progress
        bumpSnapshot()
        return RoomWireProgress(playerID: localParticipantID, progress: progress)
    }

    @discardableResult
    func finishLocalSwipe() -> RoomWireProgress? {
        guard canFinish, let localParticipantID else { return nil }
        var progress = progressByPlayer[localParticipantID] ?? RoomSwipeProgress()
        guard !progress.isFinished else { return nil }
        progress.revision += 1
        progress.isFinished = true
        progressByPlayer[localParticipantID] = progress
        updateLiveResults()
        bumpSnapshot()
        return RoomWireProgress(playerID: localParticipantID, progress: progress)
    }

    func mergeProgress(_ payload: RoomWireProgress, senderID: String) {
        guard payload.playerID == senderID,
              frozenPlayerIDs.contains(senderID),
              Set(payload.progress.decisions.keys).isSubset(of: Set(canonicalGameIDs)) else { return }

        let current = progressByPlayer[senderID]
        let merged = RoomSessionReducer.merge(incoming: payload.progress, into: current)
        guard merged != current else { return }
        progressByPlayer[senderID] = merged
        updateLiveResults()
        bumpSnapshot()
    }

    func refreshResults() {
        displayedResults = RoomSessionReducer.resultGroups(
            cards: cards,
            progressByPlayer: progressByPlayer
        )
        hasPendingResults = false
    }

    func lockOut(_ message: String) {
        phase = .lockedOut
        roomError = message
    }

    func fail(_ message: String) {
        phase = .failed
        roomError = message
    }

    func clear() {
        loadTask?.cancel()
        loadTask = nil
        state = .idle
        games = []
        sourceCards = []
        resetRoomState(keepingSource: false)
    }

    private func preferencePayload(for playerID: String) -> RoomWirePreference {
        RoomWirePreference(
            playerID: playerID,
            revision: preferenceRevisions[playerID, default: 0],
            categories: (preferences[playerID] ?? []).map(\.rawValue).sorted(),
            isReady: participants[playerID]?.isReady == true
        )
    }

    private func filteredGamesForConnectedPlayers() -> [BGGItem] {
        RoomSessionReducer.filteredGames(
            from: games,
            preferences: preferences,
            readyPlayerIDs: Set(connectedParticipants.filter(\.isReady).map(\.id))
        )
    }

    private func refreshPreStartPhase() {
        guard phase != .started, phase != .lockedOut, phase != .failed else { return }
        let matchingGames = filteredGamesForConnectedPlayers()
        phase = RoomSessionReducer.preStartPhase(
            connectedParticipants: connectedParticipants,
            sourceReadyPlayerIDs: sourceReadyPlayerIDs,
            hasLoadedSource: state == .loaded,
            hasMatchingGames: !matchingGames.isEmpty
        )

        let connectedIDs = Set(connectedParticipants.map(\.id))
        let everyoneReadyForFiltering = connectedParticipants.count >= 2
            && connectedParticipants.allSatisfy(\.isReady)
            && state == .loaded
            && connectedIDs.isSubset(of: sourceReadyPlayerIDs)
        if everyoneReadyForFiltering, matchingGames.isEmpty {
            roomError = Self.noMatchingGamesMessage
        } else if roomError == Self.noMatchingGamesMessage {
            roomError = nil
        }
    }

    private func rebuildCanonicalCards() {
        let cardsByID = Dictionary(uniqueKeysWithValues: sourceCards.map { ($0.id, $0) })
        cards = canonicalGameIDs.compactMap { cardsByID[$0] }
    }

    private func updateLiveResults() {
        let live = RoomSessionReducer.resultGroups(cards: cards, progressByPlayer: progressByPlayer)
        if live != displayedResults {
            hasPendingResults = true
        }
    }

    private func bumpSnapshot() {
        if isLocalHost {
            snapshotRevision += 1
        }
    }

    private func applySourceState(_ state: LoadState, games: [BGGItem]) {
        self.state = state
        self.games = games
        sourceCards = games.map(BoardGameCard.init(item:))
        rebuildCanonicalCards()
    }

    private func resetRoomState(keepingSource: Bool) {
        phase = .idle
        participants = [:]
        preferences = [:]
        progressByPlayer = [:]
        displayedResults = []
        hasPendingResults = false
        roomError = nil
        sessionID = nil
        authorityID = nil
        localParticipantID = nil
        frozenPlayerIDs = []
        sourceChecksum = nil
        snapshotRevision = 0
        canonicalGameIDs = []
        sourceReadyPlayerIDs = []
        preferenceRevisions = [:]
        cards = []
        if !keepingSource {
            games = []
            sourceCards = []
        }
    }
}
