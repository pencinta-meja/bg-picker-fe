//
//  LobbyScreen.swift
//  bg-picker
//

import SwiftUI

struct LobbyScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)

                Text("Ready When You Are")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                Text("Game Center matchmaking will be added next.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 48)

                HStack(spacing: 14) {
                    roomButton(
                        title: "Create\nRoom",
                        systemImage: "gamecontroller.fill"
                    )

                    roomButton(
                        title: "Join\nRoom",
                        systemImage: "person.2.fill"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background {
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        }
    }

    private func roomButton(title: String, systemImage: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.12), lineWidth: 1.5)
            }
        }
        .disabled(true)
        .accessibilityHint("Unavailable until Game Center matchmaking is implemented")
    }
}

#Preview {
    LobbyScreen()
}
