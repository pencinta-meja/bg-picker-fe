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

    init(
        isAuthenticated: Bool = true,
        isActivityReady: Bool = true,
        hasActiveRoom: Bool = false,
        matchState: RoomMatchState = .ready,
        statusMessage: String = "Ready to create or join a room.",
        errorMessage: String? = nil,
        partyCode: String? = nil,
        partyURL: URL? = nil,
        roomMemberCount: Int = 0
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
    }

    func dismissPresentedController() {
        presentedViewController = nil
    }

    private func open(code: String, status: String) {
        partyCode = code
        partyURL = URL(string: "https://gamecenter.apple.com/party/\(code)")
        hasActiveRoom = true
        roomMemberCount = 1
        matchState = .matchmaking
        errorMessage = nil
        statusMessage = status
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
            roomMemberCount: 3
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
}
#endif
