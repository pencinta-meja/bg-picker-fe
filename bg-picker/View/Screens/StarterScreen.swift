//
//  StarterScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct StarterScreen: View {
    private let isNameSet = UserManager.shared.isNameSet
    
    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            NavigationStack {
                if !isNameSet {
                    SetNameScreen()
                } else {
                    LobbyScreen()
                }
            }
        }.ignoresSafeArea(.keyboard)
    }
}
