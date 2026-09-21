//
//  bg_pickerApp.swift
//  bg-picker
//

import SwiftUI

@main
struct bg_pickerApp: App {
    @State private var gameKitManager = GameKitManager.shared
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            GameKitPresentationHost(session: gameKitManager) {
                LobbyScreen(room: gameKitManager, router: router)
            }
            .task {
                // The one place that knows about both the session and the stores, so the
                // flow teardown is wired here rather than inside a screen. Keyed to the room
                // screen leaving the stack, so backing out to the setup form drops the room
                // and its deck — not only backing all the way to the lobby.
                router.onFlowEnded = {
                    if gameKitManager.hasActiveRoom {
                        gameKitManager.disconnect()
                    }
                    SessionGameStore.shared.clear()
                }
                gameKitManager.authenticate()
            }
        }
    }
}
