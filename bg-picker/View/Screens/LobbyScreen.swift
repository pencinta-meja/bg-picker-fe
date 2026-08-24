//
//  LobbyScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct LobbyScreen: View {
    var userName: String = UserManager.shared.name
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Spacer()

                // Greeting
                Text("Hello, \(userName)")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.bottom, 48)

                // Host + Join — side by side cards
                HStack(spacing: 14) {
                    // Host Room
                    Button {
                        path.append(Route.roomSetting)
                    } label: {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Text("Host\nRoom")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.18), lineWidth: 1.5)
                        )
                    }

                    // Join Room
                    Button {
                        path.append(Route.pinInput)
                    } label: {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Text("Join\nRoom")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.18), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 24)

               
                Button {
                    path.append(Route.myGames)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.75))
                        Text("My Games")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.15), lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                Spacer()
            }
            .background {
                Image("BackgroundImage")
                    .resizable()
                    .ignoresSafeArea()
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .roomSetting:
                    RoomSettingScreen(path: $path)
                case .pinInput:
                    PinInputScreen(path: $path)
                case .waitingRoom:
                    WaitingRoomScreen(path: $path)
                case .mechanicPreference:
                    PreferenceScreen(path: $path)
                case .swiping:
                    SwipeScreen(path: $path)
                case .podium:
                    PodiumScreen(path: $path)
                case .myGames:
                    MyGamesScreen()
                }
            }
        }
    }
}

#Preview {
    LobbyScreen()
}
