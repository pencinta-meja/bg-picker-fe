//
//  PreviewSessionGameStore.swift
//  bg-picker
//
//  DEBUG-only `SessionGameStorage` conformer for Xcode previews.
//
//  The real conformer is `SessionGameStore.shared`, which only ever holds cards after
//  `load(geeklistID:)` has completed two BoardGameGeek round-trips — and that load is
//  started by `CreateRoomScreen`, which needs a Game Center room first. A preview against
//  it sits on "Loading games from the geeklist…" forever.
//
//  This poses the swipe screen as if the geeklist had already been fetched. It is a
//  preview fixture, not a simulator: it never proves a BGG request works.
//

#if DEBUG
import Foundation
import Observation

@Observable
@MainActor
final class PreviewSessionGameStore: SessionGameStorage {
    /// What a simulated load resolves to. Held so a `.failed` preview stays failed when
    /// the canvas re-triggers a load, rather than quietly healing itself.
    enum Outcome {
        case succeeds([BGGItem])
        case fails(String)
    }

    private(set) var state: SessionGameLoadState
    private(set) var games: [BGGItem]
    private(set) var cards: [BoardGameCard]

    private let outcome: Outcome
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// `cards` is deliberately not a parameter: it is always derived from `games`, so this
    /// cannot pose a state the real store could never reach.
    init(
        state: SessionGameLoadState = .loaded,
        games: [BGGItem] = PreviewBoardGames.all,
        outcome: Outcome? = nil
    ) {
        self.state = state
        self.games = games
        self.cards = games.map(BoardGameCard.init(item:))
        self.outcome = outcome ?? .succeeds(games.isEmpty ? PreviewBoardGames.all : games)
    }

    // The actions move state so previews stay interactive rather than frozen.

    /// Poses the real two-step load — `.loading`, then a resolution — without touching
    /// `BGGService`. The delay is what makes the spinner visible in the canvas.
    func load(geeklistID: String) {
        loadTask?.cancel()
        apply(state: .loading, games: [])

        loadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, let self else { return }

            switch self.outcome {
            case .succeeds(let games):
                self.apply(state: .loaded, games: games)
            case .fails(let message):
                self.apply(state: .failed(message), games: [])
            }
        }
    }

    func clear() {
        loadTask?.cancel()
        loadTask = nil
        apply(state: .idle, games: [])
    }

    /// Mirrors the real store: one place where status and data move together.
    private func apply(state: SessionGameLoadState, games: [BGGItem]) {
        self.state = state
        self.games = games
        self.cards = games.map(BoardGameCard.init(item:))
    }
}

// The states the screens actually branch on.
extension PreviewSessionGameStore {
    /// A geeklist already fetched — the full deck, ready to swipe.
    static var loaded: PreviewSessionGameStore {
        PreviewSessionGameStore()
    }

    /// Before a room is created, or after `clear()`.
    static var idle: PreviewSessionGameStore {
        PreviewSessionGameStore(state: .idle, games: [])
    }

    static var loading: PreviewSessionGameStore {
        PreviewSessionGameStore(state: .loading, games: [])
    }

    /// `.loaded` with no cards: the geeklist genuinely had no board games in it. The one
    /// branch that is impossible to reach by accident.
    static var loadedEmpty: PreviewSessionGameStore {
        PreviewSessionGameStore(state: .loaded, games: [])
    }

    /// A single card, so the swipe-through end state and the enabled Finish button are one
    /// gesture away instead of seven.
    static var lastCard: PreviewSessionGameStore {
        PreviewSessionGameStore(games: [PreviewBoardGames.catan])
    }

    /// Defaulted to a message shaped like a real `BGGError.invalidResponse` description,
    /// so the failure preview shows realistic wrapping rather than "Error".
    static func failed(
        _ message: String = "BoardGameGeek returned status 429. The API is rate-limiting requests — wait a moment and try again."
    ) -> PreviewSessionGameStore {
        PreviewSessionGameStore(state: .failed(message), games: [], outcome: .fails(message))
    }
}
#endif
