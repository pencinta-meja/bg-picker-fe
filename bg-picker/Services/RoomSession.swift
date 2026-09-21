//
//  RoomSession.swift
//  bg-picker
//
//  The frontend-facing multiplayer boundary.
//
//  Screens depend on this protocol rather than on `GameKitManager`, so a preview can
//  inject a posed session instead of waiting on a Game Center sign-in most contributors
//  cannot complete — the contributors hold separate Individual memberships, so only the
//  App ID's owner can authenticate at all.
//
//  `GameKitManager.shared` is the production conformer; `PreviewRoomSession` under
//  `ViewTest` is the DEBUG-only one.
//
//  Only what the UI actually reads belongs here. Packet send/receive stays on
//  `GameKitManager` until a screen needs it.
//

import Foundation
import Observation
import UIKit

/// Where the room is in its lifecycle. Raw values are display strings.
enum RoomMatchState: String {
    case idle = "Not ready"
    case loadingActivity = "Loading room service"
    case ready = "Ready"
    case matchmaking = "Finding room members"
    case connected = "Connected"
    case failed = "Needs attention"
}

/// Refining `Observable` is what lets a view hold `any RoomSession` and still re-render:
/// the conformer's getter registers the read whichever way it was reached. It also turns
/// a conformer that forgot `@Observable` into a compile error rather than a dead view.
@MainActor
protocol RoomSession: AnyObject, Observable {
    var isAuthenticated: Bool { get }
    var isActivityReady: Bool { get }
    var hasActiveRoom: Bool { get }
    var matchState: RoomMatchState { get }
    var statusMessage: String { get }
    var errorMessage: String? { get }
    var partyCode: String? { get }
    var partyURL: URL? { get }
    /// Local player included; 0 when there is no room.
    var roomMemberCount: Int { get }
    var presentedViewController: UIViewController? { get }

    func authenticate()
    func createRoom()
    func joinRoom(code: String)
    func disconnect()
    func dismissPresentedController()
}

/// Party-code text handling. Pure string work with no GameKit in it, so a view can format
/// input without naming the concrete manager.
enum PartyCode {
    /// Uppercases, drops separators, caps at six characters, and reinserts the dash.
    static func normalize(_ input: String) -> String {
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
}
