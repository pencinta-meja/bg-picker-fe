//
//  bg_pickerApp.swift
//  bg-picker
//

import SwiftUI
import SwiftData

@main
struct bg_pickerApp: App {
    let container: ModelContainer = {
        let schema = Schema([BoardGame.self]) 
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            let viewModel = CollectionViewModel(    modelContext: container.mainContext)
            FirstScreen()
                .environment(viewModel)
                .modelContainer(container)
        }
    }
}

struct FirstScreen: View {
    @ObservedObject var userManager = UserManager.shared

    var body: some View {
        if userManager.isNameSet {
            LobbyScreen().transition(.opacity)
        } else {
            SetNameScreen(goToLobby: $userManager.isNameSet)
        }
    }
}
