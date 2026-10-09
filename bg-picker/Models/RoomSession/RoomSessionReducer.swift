import Foundation

nonisolated enum RoomSessionReducer {
    static func canStart(
        connectedParticipants: [RoomParticipant],
        sourceReadyPlayerIDs: Set<String>,
        hasLoadedSource: Bool,
        hasMatchingGames: Bool
    ) -> Bool {
        preStartPhase(
            connectedParticipants: connectedParticipants,
            sourceReadyPlayerIDs: sourceReadyPlayerIDs,
            hasLoadedSource: hasLoadedSource,
            hasMatchingGames: hasMatchingGames
        ) == .readyToStart
    }

    static func preStartPhase(
        connectedParticipants: [RoomParticipant],
        sourceReadyPlayerIDs: Set<String>,
        hasLoadedSource: Bool,
        hasMatchingGames: Bool
    ) -> RoomGamePhase {
        guard connectedParticipants.count >= 2 else { return .waitingForPlayers }
        guard hasLoadedSource,
              Set(connectedParticipants.map(\.id)).isSubset(of: sourceReadyPlayerIDs) else {
            return .synchronizing
        }
        guard connectedParticipants.allSatisfy(\.isReady), hasMatchingGames else {
            return .waitingForReady
        }
        return .readyToStart
    }

    static func filteredGames(
        from games: [BGGItem],
        preferences: [String: Set<BoardGameCategoryGroup>],
        readyPlayerIDs: Set<String>
    ) -> [BGGItem] {
        let selectedGroups = readyPlayerIDs.reduce(into: Set<BoardGameCategoryGroup>()) { result, playerID in
            result.formUnion(preferences[playerID] ?? [])
        }

        guard !selectedGroups.isEmpty else { return games }
        return games.filter { !selectedGroups.isDisjoint(with: Set($0.categoryGroups)) }
    }

    static func merge(
        incoming: RoomSwipeProgress,
        into current: RoomSwipeProgress?
    ) -> RoomSwipeProgress {
        guard let current else { return incoming }
        guard !current.isFinished, incoming.revision > current.revision else { return current }
        return incoming
    }

    static func electedAuthority(
        participants: [String: RoomParticipant],
        eligiblePlayerIDs: Set<String>
    ) -> String? {
        eligiblePlayerIDs
            .filter { participants[$0]?.isConnected == true }
            .sorted()
            .first
    }

    static func resultGroups(
        cards: [BoardGameCard],
        progressByPlayer: [String: RoomSwipeProgress]
    ) -> [RoomResultGroup] {
        let finished = progressByPlayer.values.filter(\.isFinished)
        let finishedCount = finished.count
        guard finishedCount > 0 else { return [] }

        var votes: [String: Int] = [:]
        for progress in finished {
            for gameID in progress.acceptedGameIDs {
                votes[gameID, default: 0] += 1
            }
        }

        let canonicalIndex = Dictionary(uniqueKeysWithValues: cards.enumerated().map { ($0.element.id, $0.offset) })
        let cardsByVoteCount = Dictionary(grouping: cards.filter { votes[$0.id, default: 0] > 0 }) {
            votes[$0.id, default: 0]
        }

        return cardsByVoteCount.keys.sorted(by: >).map { voteCount in
            RoomResultGroup(
                voteCount: voteCount,
                finishedPlayerCount: finishedCount,
                cards: (cardsByVoteCount[voteCount] ?? []).sorted {
                    canonicalIndex[$0.id, default: .max] < canonicalIndex[$1.id, default: .max]
                }
            )
        }
    }
}
