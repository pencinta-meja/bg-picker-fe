import XCTest
@testable import bg_picker

final class RoomSessionReducerTests: XCTestCase {
    func testCategoryPreferencesUseUnionAndNoSelectionKeepsFullSource() {
        let games = [
            game(id: "fantasy", category: "Fantasy"),
            game(id: "party", category: "Party Game"),
            game(id: "economic", category: "Economic")
        ]

        let unfiltered = RoomSessionReducer.filteredGames(
            from: games,
            preferences: [:],
            readyPlayerIDs: ["a", "b"]
        )
        XCTAssertEqual(unfiltered.map(\.id), ["fantasy", "party", "economic"])

        let filtered = RoomSessionReducer.filteredGames(
            from: games,
            preferences: [
                "a": [.fantasyAndSciFi],
                "b": [.partyAndPopCulture]
            ],
            readyPlayerIDs: ["a", "b"]
        )
        XCTAssertEqual(filtered.map(\.id), ["fantasy", "party"])
    }

    func testStartRequiresTwoReadySourceSynchronizedPlayersAndMatchingGames() {
        let players = [
            participant("a", ready: true),
            participant("b", ready: true)
        ]

        XCTAssertTrue(RoomSessionReducer.canStart(
            connectedParticipants: players,
            sourceReadyPlayerIDs: ["a", "b"],
            hasLoadedSource: true,
            hasMatchingGames: true
        ))
        XCTAssertFalse(RoomSessionReducer.canStart(
            connectedParticipants: players,
            sourceReadyPlayerIDs: ["a"],
            hasLoadedSource: true,
            hasMatchingGames: true
        ))
        XCTAssertFalse(RoomSessionReducer.canStart(
            connectedParticipants: [participant("a", ready: true), participant("b", ready: false)],
            sourceReadyPlayerIDs: ["a", "b"],
            hasLoadedSource: true,
            hasMatchingGames: true
        ))
    }

    @MainActor
    func testStartFreezesRosterAndAllowsOnlyKnownPlayerToReconnect() {
        let store = startedStore()

        XCTAssertEqual(store.frozenPlayerIDs, ["a", "b"])
        store.disconnectParticipant(id: "b")
        XCTAssertTrue(store.connectParticipant(id: "b", displayName: "B Returned"))
        XCTAssertFalse(store.connectParticipant(id: "late", displayName: "Late Player"))
        XCTAssertEqual(store.participants["b"]?.displayName, "B Returned")
        XCTAssertEqual(store.participants["b"]?.isConnected, true)
    }

    @MainActor
    func testDuplicateConnectionDoesNotResetReadyButReconnectBeforeStartDoes() {
        let store = SessionGameStore()
        store.beginHosting(localID: "a", displayName: "A")
        store.applyReplicatedSource([game(id: "1", category: "Fantasy")], checksum: "checksum")
        XCTAssertTrue(store.connectParticipant(id: "b", displayName: "B"))
        store.markSourceReady(playerID: "b")
        store.mergePreference(
            RoomWirePreference(playerID: "b", revision: 1, categories: [], isReady: true),
            senderID: "b"
        )

        XCTAssertTrue(store.connectParticipant(id: "b", displayName: "B"))
        XCTAssertEqual(store.participants["b"]?.isReady, true)

        store.disconnectParticipant(id: "b")
        XCTAssertTrue(store.connectParticipant(id: "b", displayName: "B"))
        XCTAssertEqual(store.participants["b"]?.isReady, false)
    }

    func testProgressRevisionsIgnoreDuplicatesAndFinishedSubmissionIsPermanent() {
        let current = RoomSwipeProgress(
            revision: 2,
            decisions: ["one": .accepted],
            isFinished: false
        )
        let duplicate = RoomSwipeProgress(
            revision: 2,
            decisions: ["one": .rejected],
            isFinished: false
        )
        XCTAssertEqual(RoomSessionReducer.merge(incoming: duplicate, into: current), current)

        let finished = RoomSwipeProgress(
            revision: 3,
            decisions: ["one": .accepted],
            isFinished: true
        )
        let attemptedChange = RoomSwipeProgress(
            revision: 4,
            decisions: ["one": .rejected],
            isFinished: true
        )
        XCTAssertEqual(RoomSessionReducer.merge(incoming: attemptedChange, into: finished), finished)
    }

    @MainActor
    func testLocalFinishedSubmissionCannotBeChangedOrRestarted() {
        let store = startedStore()
        for card in store.cards {
            XCTAssertNotNil(store.recordLocalDecision(gameID: card.id, accepted: false))
        }
        XCTAssertNotNil(store.finishLocalSwipe())
        XCTAssertTrue(store.localProgress.isFinished)
        XCTAssertTrue(store.localProgress.acceptedGameIDs.isEmpty)

        let firstID = try! XCTUnwrap(store.cards.first?.id)
        XCTAssertNil(store.recordLocalDecision(gameID: firstID, accepted: true))
        XCTAssertNil(store.finishLocalSwipe())
    }

    @MainActor
    func testAuthoritativeSnapshotCannotRollBackNewerLocalFinishedProgress() {
        let store = startedStore()
        for card in store.cards {
            XCTAssertNotNil(store.recordLocalDecision(gameID: card.id, accepted: true))
        }
        XCTAssertNotNil(store.finishLocalSwipe())
        let finished = store.localProgress

        let snapshot = RoomWireSnapshot(
            sessionID: try! XCTUnwrap(store.sessionID),
            authorityID: "a",
            revision: store.snapshotRevision + 1,
            phase: .started,
            participants: [
                RoomWireParticipant(id: "a", displayName: "A", isConnected: true, isReady: true),
                RoomWireParticipant(id: "b", displayName: "B", isConnected: true, isReady: true)
            ],
            preferences: [],
            progress: [],
            frozenPlayerIDs: ["a", "b"],
            canonicalGameIDs: store.canonicalGameIDs,
            sourceChecksum: store.sourceChecksum
        )

        store.configureFromSnapshot(snapshot)
        XCTAssertEqual(store.localProgress, finished)
    }

    @MainActor
    func testNewFinishedSubmissionStaysPendingUntilManualRefresh() {
        let store = startedStore()
        for card in store.cards {
            XCTAssertNotNil(store.recordLocalDecision(gameID: card.id, accepted: true))
        }
        XCTAssertNotNil(store.finishLocalSwipe())
        XCTAssertTrue(store.hasPendingResults)
        XCTAssertTrue(store.displayedResults.isEmpty)

        store.refreshResults()
        XCTAssertEqual(store.displayedResults.first?.finishedPlayerCount, 1)
        XCTAssertFalse(store.hasPendingResults)

        let remoteDecisions = Dictionary(uniqueKeysWithValues: store.cards.map { ($0.id, RoomSwipeDecision.rejected) })
        store.mergeProgress(
            RoomWireProgress(
                playerID: "b",
                progress: RoomSwipeProgress(revision: 3, decisions: remoteDecisions, isFinished: true)
            ),
            senderID: "b"
        )

        XCTAssertTrue(store.hasPendingResults)
        XCTAssertEqual(store.displayedResults.first?.finishedPlayerCount, 1)
        store.refreshResults()
        XCTAssertEqual(store.displayedResults.first?.finishedPlayerCount, 2)
    }

    func testHostElectionUsesLowestConnectedFrozenPlayerID() {
        let players = [
            "z": participant("z", connected: false),
            "b": participant("b"),
            "a": participant("a")
        ]

        XCTAssertEqual(
            RoomSessionReducer.electedAuthority(
                participants: players,
                eligiblePlayerIDs: ["z", "b", "a"]
            ),
            "a"
        )
    }

    @MainActor
    func testResultsCountOnlyFinishedPlayersOmitZeroVotesAndKeepCanonicalTieOrder() {
        let cards = [card("first"), card("second"), card("zero")]
        let progress: [String: RoomSwipeProgress] = [
            "a": .init(revision: 3, decisions: ["first": .accepted, "second": .accepted], isFinished: true),
            "b": .init(revision: 3, decisions: ["first": .accepted, "second": .accepted], isFinished: true),
            "c": .init(revision: 3, decisions: ["first": .accepted, "second": .rejected], isFinished: true),
            "unfinished": .init(revision: 1, decisions: ["zero": .accepted], isFinished: false)
        ]

        let groups = RoomSessionReducer.resultGroups(cards: cards, progressByPlayer: progress)

        XCTAssertEqual(groups.map(\.title), ["3/3 Matches", "2/3 Matches"])
        XCTAssertEqual(groups[0].cards.map(\.id), ["first"])
        XCTAssertEqual(groups[1].cards.map(\.id), ["second"])
        XCTAssertFalse(groups.flatMap(\.cards).contains { $0.id == "zero" })

        let tied = RoomSessionReducer.resultGroups(
            cards: cards,
            progressByPlayer: [
                "a": .init(
                    revision: 3,
                    decisions: ["first": .accepted, "second": .accepted, "zero": .rejected],
                    isFinished: true
                )
            ]
        )
        XCTAssertEqual(tied.first?.cards.map(\.id), ["first", "second"])
    }

    @MainActor
    private func startedStore() -> SessionGameStore {
        let store = SessionGameStore()
        store.beginHosting(localID: "a", displayName: "A")
        store.applyReplicatedSource(
            [
                game(id: "one", category: "Fantasy"),
                game(id: "two", category: "Economic")
            ],
            checksum: "checksum"
        )
        XCTAssertTrue(store.connectParticipant(id: "b", displayName: "B"))
        store.markSourceReady(playerID: "b")
        XCTAssertNotNil(store.setLocalReady(categories: []))
        store.mergePreference(
            RoomWirePreference(playerID: "b", revision: 1, categories: [], isReady: true),
            senderID: "b"
        )
        XCTAssertTrue(store.startGame())
        return store
    }

    private func participant(
        _ id: String,
        connected: Bool = true,
        ready: Bool = true
    ) -> RoomParticipant {
        RoomParticipant(id: id, displayName: id.uppercased(), isConnected: connected, isReady: ready)
    }

    private func game(id: String, category: String) -> BGGItem {
        BGGItem(
            id: id,
            names: [BGGNameAttr(type: "primary", value: id)],
            description: "Description for \(id)",
            yearPublished: nil,
            minPlayers: nil,
            maxPlayers: nil,
            playingTime: nil,
            minPlayTime: nil,
            maxPlayTime: nil,
            image: nil,
            thumbnail: nil,
            links: [BGGLinkAttr(type: "boardgamecategory", id: nil, value: category)],
            statistics: nil
        )
    }

    private func card(_ id: String) -> BoardGameCard {
        BoardGameCard(
            id: id,
            title: id,
            description: "Description",
            thumbnailURL: nil,
            gameplayImageURL: nil,
            thumbnailLocalImage: nil,
            gameplayLocalImage: nil,
            categoriesText: "—",
            playTimeText: "—",
            playersText: "—",
            complexityText: "—",
            ratingText: "—"
        )
    }
}
