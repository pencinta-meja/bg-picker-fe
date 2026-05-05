//
//  LaunchScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct LauchScreen: View {
    @State private var isActive: Bool = false
    var body: some View {
        if !isActive {
            ZStack {
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Image("DiceIcon")
            }.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        } else {
            StarterScreen()
        }
    }
}

#Preview {
    LauchScreen()
}
