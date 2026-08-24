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
            GameKitPresentationHost(manager: gameKitManager) {
                LobbyScreen(gameKitManager: gameKitManager)
            }
            .task {
                gameKitManager.authenticate()
            }
        }
    }
}
