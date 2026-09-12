//
//  SessionGameStore.swift
//  bg-picker
//
//  Holds the games loaded for the current room, and the status of that load.
//
//  This is deliberately a store rather than a view model: the data outlives any one
//  screen. The load is started on CreateRoomScreen and observed on SwipeScreen, so a
//  per-view owner would render `.idle` over a request that is still in flight.
//
//  Everything here is in memory and is dropped by `clear()` when a room ends.
//

import Foundation
import Combine

@MainActor
final class SessionGameStore: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        /// Loaded with no cards means the geeklist genuinely had no board games —
        /// a result, not a failure, and not a spinner that never resolves.
        case loaded
        case failed(String)
    }

    static let shared = SessionGameStore()

    /// Internal rather than `private` (unlike `GameKitManager`'s) so previews and
    /// tests can build an isolated instance instead of mutating shared state.
    init() {}

    @Published private(set) var state: LoadState = .idle
    /// Canonical fetched data. Kept as `BGGItem` rather than only the mapped cards so
    /// later filtering (mechanics, player count) still has the domain fields.
    @Published private(set) var games: [BGGItem] = []
    /// Derived once when the load finishes, not recomputed on every render.
    @Published private(set) var cards: [BoardGameCard] = []

    private var loadTask: Task<Void, Never>?

    var isLoading: Bool { state == .loading }
    var hasGames: Bool { !cards.isEmpty }

    func load(geeklistID: String) {
        loadTask?.cancel()
        apply(state: .loading, games: [])

        loadTask = Task { [weak self] in
            do {
                let games = try await BGGService.shared.fetchGeeklistGames(id: geeklistID)
                guard !Task.isCancelled else { return }
                self?.apply(state: .loaded, games: games)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.apply(state: .failed(error.localizedDescription), games: [])
            }
        }
    }

    /// Parses a pasted URL or a typed id, then loads. Returns false if the input
    /// carried no usable geeklist id.
    @discardableResult
    func load(fromInput input: String) -> Bool {
        guard let id = BGGService.geeklistID(from: input) else { return false }
        load(geeklistID: id)
        return true
    }

    /// Called when a room ends. Without this a singleton would carry one room's deck
    /// into the next.
    func clear() {
        loadTask?.cancel()
        loadTask = nil
        apply(state: .idle, games: [])
    }

    /// The single place status and data change together, so the two cannot diverge.
    private func apply(state: LoadState, games: [BGGItem]) {
        self.state = state
        self.games = games
        self.cards = games.map(BoardGameCard.init(item:))
    }
}
