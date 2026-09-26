//
//  SessionGameStorage.swift
//  bg-picker
//
//  The frontend-facing boundary for the current room's game data.
//
//  Screens depend on this protocol rather than on `SessionGameStore`, so a preview can
//  pose a fetched deck instead of waiting on two BoardGameGeek round-trips that only
//  start once a real room has been created.
//
//  `SessionGameStore.shared` is the production conformer; `PreviewSessionGameStore` under
//  `UIMocks` is the DEBUG-only one.
//
//  Only what the UI actually reads belongs here. `load(fromInput:)` stays on
//  `SessionGameStore` until a screen needs it — `CreateRoomScreen` validates the URL
//  itself and calls `load(geeklistID:)`.
//

import Foundation
import Observation

/// Where the current room's geeklist load stands.
///
/// Top-level rather than nested in `SessionGameStore`, so the abstraction never names
/// one of its own conformers.
nonisolated enum SessionGameLoadState: Equatable {
    case idle
    case loading
    /// Loaded with no cards means the geeklist genuinely had no board games —
    /// a result, not a failure, and not a spinner that never resolves.
    case loaded
    case failed(String)
}

/// Refining `Observable` is what lets a view hold `any SessionGameStorage` and still
/// re-render: the conformer's getter registers the read whichever way it was reached.
/// It also turns a conformer that forgot `@Observable` into a compile error rather than
/// a dead view. Same reasoning as `RoomSession`.
@MainActor
protocol SessionGameStorage: AnyObject, Observable {
    var state: SessionGameLoadState { get }
    /// Canonical fetched data, kept alongside `cards` so later filtering still has the
    /// domain fields.
    var games: [BGGItem] { get }
    /// Derived from `games` when a load finishes. A conformer must never let the two
    /// diverge.
    var cards: [BoardGameCard] { get }

    func load(geeklistID: String)
    func clear()
}

/// Read-only conveniences, implemented once here rather than per conformer. The getters
/// reach `state` and `cards` through `self`, so Observation still registers the read.
extension SessionGameStorage {
    var isLoading: Bool { state == .loading }
    var hasGames: Bool { !cards.isEmpty }
}
