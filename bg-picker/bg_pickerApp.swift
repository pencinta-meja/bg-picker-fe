//
//  bg_pickerApp.swift
//  bg-picker
//
//  Created by Danniel on 02/05/26.
//

import SwiftUI

@main
struct bg_pickerApp: App {
    var body: some Scene {
        WindowGroup {
            FirstScreen()
        }
    }
}

struct FirstScreen: View {
    @State var isNameSet : Bool = UserManager.shared.isNameSet
    
    var body: some View {
        if !isNameSet {
            SetNameScreen(goToLobby: $isNameSet)
        } else {
            LobbyScreen().transition(.opacity)
        }
    }
}
