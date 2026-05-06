//
//  SetNameScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct SetNameScreen: View {
    @StateObject var viewModel: SetNameViewModel = SetNameViewModel()
    @FocusState var isFocused: Bool
    @Binding var goToLobby: Bool
    
    var body: some View {
        VStack (spacing: 0) {
            VStack(spacing: 100) {
                Spacer()
                
                Text("Who is this?")
                    .foregroundStyle(.white)
                    .font(Font.title)
                
                HStack(alignment: .center, spacing: 4) {
                    TextField("Plain", text: $viewModel.name, prompt:
                                Text("Your Name")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                    )
                    .focused($isFocused)
                    .font(.headline)
                    .tint(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.leading, 1)
                    .glassEffect(.clear, in: .rect(cornerRadius: 10))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isFocused = true
                        }
                    }
                    .onChange(of: isFocused) { _, newValue in
                        if !newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }
                    }
                    .onChange(of: viewModel.name) { _, newValue in
                        if newValue.count > 20 {
                            viewModel.name = String(newValue.prefix(20))
                        }
                    }
                    .modifier(ShakeEffect(shakes: viewModel.shouldShake ? 2 : 0))
                    .animation(Animation.default.repeatCount(2).speed(10), value: viewModel.shouldShake)
                    
                }
                .padding(.horizontal, 52)
                .padding(.vertical, 6)
            }
            
            VStack (spacing: 0) {
                Spacer()
                NextPrimaryButton(action: {
                    self.viewModel.saveName {
                        self.goToLobby = true
                    }
                })
                .padding(.vertical, 88)
                .padding(.horizontal, 52)
            }
        }
        .background() {
            Image("BackgroundImage")
                .resizable()
                .ignoresSafeArea()
        }
    }
}

// Taken from this: https://stackoverflow.com/questions/65480452/swiftui-textfield-shake-animation-when-input-is-not-valid
// idk what that does
struct ShakeEffect: GeometryEffect {
        func effectValue(size: CGSize) -> ProjectionTransform {
            return ProjectionTransform(CGAffineTransform(translationX: -30 * sin(position * 2 * .pi), y: 0))
        }
        
        init(shakes: Int) {
            position = CGFloat(shakes)
        }
        
        var position: CGFloat
        var animatableData: CGFloat {
            get { position }
            set { position = newValue }
        }
    }

#Preview {
    SetNameScreen(goToLobby: .constant(false) )
}
    
