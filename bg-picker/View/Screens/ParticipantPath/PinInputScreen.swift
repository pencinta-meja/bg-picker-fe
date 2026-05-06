//
//  PinInputScreen.swift
//  bg-picker
//
//  Created by Danniel on 07/05/26.
//

import SwiftUI

struct PinInputScreen: View {
    var userName: String = UserManager.shared.name
    
    @Binding var path: NavigationPath
    
    @State private var pin: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("Join Room")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 26)
            }
            
            Spacer()
            
            VStack(spacing: 100) {
                TextField("PIN", text: $pin, prompt:
                            Text("PIN")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                )
                .focused($isFocused)
                .font(.system(size: 48, weight: .bold))
                .tint(.white)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isFocused = true
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                NextPrimaryButton(action: {})
                    .padding(.bottom, 88)
                    .padding(.horizontal, 52)
            }
        }
        .background {
            Image("BackgroundImage")
                .resizable()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    PinInputScreen(path: .constant(NavigationPath()))
}
