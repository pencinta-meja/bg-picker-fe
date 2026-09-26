//
//  SessionGameStore.swift
//  bg-picker
//
//  Holds the games loaded for the current room, and the status of that load.
//
//  The production conformer of `SessionGameStorage`; `PreviewSessionGameStore` is the
//  DEBUG-only one. Screens hold `any SessionGameStorage` and never name this type,
//  except the composition root in `App`, which owns the lifecycle.
//
//  This is deliberately a store rather than a view model: the data outlives any one
//  screen. The load is started on CreateRoomScreen and observed on SwipeScreen, so a
//  per-view owner would render `.idle` over a request that is still in flight.
//
//  Everything here is in memory and is dropped by `clear()` when a room ends.
//

import Foundation
import Observation

/// `@Observable` rather than `ObservableObject`, because `@ObservedObject` cannot hold a
/// protocol while Observation tracks reads made through `any SessionGameStorage`
/// correctly. Same reason `GameKitManager` is `@Observable`.
@Observable
@MainActor
final class SessionGameStore: SessionGameStorage {
    static let shared = SessionGameStore()

    /// Internal rather than `private` (unlike `GameKitManager`'s) so previews and
    /// tests can build an isolated instance instead of mutating shared state.
    init() {}

    private(set) var state: SessionGameLoadState = .idle
    /// Canonical fetched data. Kept as `BGGItem` rather than only the mapped cards so
    /// later filtering (mechanics, player count) still has the domain fields.
    private(set) var games: [BGGItem] = []
    /// Derived once when the load finishes, not recomputed on every render.
    private(set) var cards: [BoardGameCard] = []

    /// Control state no view reads, so it stays out of the observation registrar.
    @ObservationIgnored private var loadTask: Task<Void, Never>?

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
    ///
    /// Off `SessionGameStorage`: no screen calls it yet, so it stays concrete.
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
    private func apply(state: SessionGameLoadState, games: [BGGItem]) {
        self.state = state
        self.games = games
        self.cards = games.map(BoardGameCard.init(item:))
    }
}
