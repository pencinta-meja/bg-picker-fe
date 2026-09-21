import SwiftUI

struct LobbyScreen: View {
    let room: any RoomSession
    let router: AppRouter

    var body: some View {
        NavigationStack(path: router.pathBinding) {
            AppBackground {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer(minLength: 72)

                            Image("LogoApp")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 180)
                                .accessibilityHidden(true)

                            Text("“Ready When You Are”")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.top, 22)

                            Spacer(minLength: 92)

                            VStack(spacing: 14) {
                                PrimaryButton(title: "Create Room") {
                                    router.push(.createRoom)
                                }

                                PrimaryButton(title: "Join Room", style: .outlined) {
                                    router.push(.joinRoom)
                                }
                            }
                            .disabled(!canEnterRoomSetup)

                            if shouldShowGameCenterStatus {
                                gameCenterStatus
                                    .padding(.top, 18)
                            }

                            Spacer(minLength: 56)
                        }
                        .padding(.horizontal, 36)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                RouteDestinationView(route: route, room: room, router: router)
            }
            // The only forward move the lobby still owns: a room nobody on screen asked for,
            // handed over by Game Center when another player accepts a party link. Create and
            // Join route their own rooms, and by then the lobby is not on top.
            .onChange(of: room.partyCode, initial: true) { _, code in
                if code != nil, router.isAtLobby {
                    router.enterRoom()
                }
            }
        }
        .tint(.white)
    }

    private var canEnterRoomSetup: Bool {
        room.isAuthenticated
            && room.isActivityReady
            && !room.hasActiveRoom
    }

    private var shouldShowGameCenterStatus: Bool {
        room.errorMessage != nil || !room.isActivityReady
    }

    private var gameCenterStatus: some View {
        HStack(spacing: 10) {
            if room.matchState == .loadingActivity {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: room.errorMessage == nil
                    ? "gamecontroller"
                    : "exclamationmark.triangle.fill")
            }

            Text(room.statusMessage)
                .font(.footnote)
                .multilineTextAlignment(.leading)

            if room.isAuthenticated,
               !room.isActivityReady,
               room.matchState != .loadingActivity {
                Button("Retry") {
                    room.authenticate()
                }
                .font(.footnote.bold())
            }
        }
        .foregroundStyle(
            room.errorMessage == nil
                ? .white.opacity(0.72)
                : Color.red.opacity(0.9)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("Ready") {
    LobbyScreen(room: PreviewRoomSession.ready, router: AppRouter())
}

#Preview("Signed out") {
    LobbyScreen(room: PreviewRoomSession.signedOut, router: AppRouter())
}

#Preview("Activity failed") {
    LobbyScreen(room: PreviewRoomSession.failed(), router: AppRouter())
}
#endif
