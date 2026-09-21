import SwiftUI

struct LobbyScreen: View {
    let room: any RoomSession

    @State private var path = NavigationPath()
    @State private var geeklistLink = ""
    @State private var selectedGroups: Set<BoardGameCategoryGroup> = []

    var body: some View {
        NavigationStack(path: $path) {
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
                                    path.append(Route.createRoom)
                                }

                                PrimaryButton(title: "Join Room", style: .outlined) {
                                    path.append(Route.joinRoom)
                                }
                            }
                            .disabled(!canEnterRoomSetup)

                            #if DEBUG
                            NavigationLink("Geeklist test (debug)") {
                                GeeklistTestScreen()
                            }
                            .font(.footnote.bold())
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.top, 20)
                            #endif

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
                switch route {
                case .createRoom:
                    CreateRoomScreen(
                        room: room,
                        geeklistLink: $geeklistLink
                    )
                case .joinRoom:
                    JoinRoomScreen(room: room)
                case .categoryPreference:
                    PreferenceScreen(
                        room: room,
                        selectedGroups: $selectedGroups,
                        path: $path
                    )
                case .swiping:
                    SwipeScreen(path: $path)
                case .podium:
                    PodiumScreen(path: $path)
                }
            }
            .onAppear {
                routeToPreferenceIfRoomIsActive()
            }
            .onChange(of: room.partyCode) { _, code in
                if code != nil {
                    routeToPreferenceIfRoomIsActive()
                }
            }
            .onChange(of: path.count) { previousCount, newCount in
                if previousCount > 0, newCount == 0 {
                    endRoomSetup()
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

    private func routeToPreferenceIfRoomIsActive() {
        guard room.partyCode != nil else { return }

        var destination = NavigationPath()
        destination.append(Route.categoryPreference)
        path = destination
    }

    private func endRoomSetup() {
        if room.hasActiveRoom {
            room.disconnect()
        }
        geeklistLink = ""
        SessionGameStore.shared.clear()
        selectedGroups.removeAll()
    }
}

#if DEBUG
#Preview("Ready") {
    LobbyScreen(room: PreviewRoomSession.ready)
}

#Preview("Signed out") {
    LobbyScreen(room: PreviewRoomSession.signedOut)
}

#Preview("Activity failed") {
    LobbyScreen(room: PreviewRoomSession.failed())
}
#endif
