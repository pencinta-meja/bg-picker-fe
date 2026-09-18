//
//  bg_pickerApp.swift
//  bg-picker
//

import SwiftUI

@main
struct bg_pickerApp: App {
    @StateObject private var gameKitManager = GameKitManager.shared

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Boot straight into the geeklist harness, skipping the Game Center gate:
            //   xcrun simctl launch <device> <bundle-id> -GeeklistTest
            // In Xcode: Product > Scheme > Edit Scheme > Run > Arguments.
            if ProcessInfo.processInfo.arguments.contains("-GeeklistTest") {
                NavigationStack {
                    GeeklistTestScreen()
                }
            } else {
                lobby
            }
            #else
            lobby
            #endif
        }
    }

    private var lobby: some View {
        GameKitPresentationHost(manager: gameKitManager) {
            LobbyScreen(gameKitManager: gameKitManager)
        }
        .task {
            gameKitManager.authenticate()
        }
    }
}
