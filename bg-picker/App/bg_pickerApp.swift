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
                // flow teardown is wired here rather than inside a screen.
                router.onReturnToLobby = {
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
