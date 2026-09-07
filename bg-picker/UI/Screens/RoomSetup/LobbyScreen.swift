import SwiftUI

struct LobbyScreen: View {
    @ObservedObject var gameKitManager: GameKitManager

    @State private var path = NavigationPath()
    @State private var collectionLink = ""
    @State private var selectedMechanics: Set<Mechanic> = []

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
                        gameKitManager: gameKitManager,
                        collectionLink: $collectionLink
                    )
                case .joinRoom:
                    JoinRoomScreen(gameKitManager: gameKitManager)
                case .mechanicPreference:
                    PreferenceScreen(
                        gameKitManager: gameKitManager,
                        selectedMechanics: $selectedMechanics,
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
            .onChange(of: gameKitManager.partyCode) { _, code in
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
        gameKitManager.isAuthenticated
            && gameKitManager.isActivityReady
            && !gameKitManager.hasActiveRoom
    }

    private var shouldShowGameCenterStatus: Bool {
        gameKitManager.errorMessage != nil || !gameKitManager.isActivityReady
    }

    private var gameCenterStatus: some View {
        HStack(spacing: 10) {
            if gameKitManager.matchState == .loadingActivity {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: gameKitManager.errorMessage == nil
                    ? "gamecontroller"
                    : "exclamationmark.triangle.fill")
            }

            Text(gameKitManager.statusMessage)
                .font(.footnote)
                .multilineTextAlignment(.leading)

            if gameKitManager.isAuthenticated,
               !gameKitManager.isActivityReady,
               gameKitManager.matchState != .loadingActivity {
                Button("Retry") {
                    gameKitManager.authenticate()
                }
                .font(.footnote.bold())
            }
        }
        .foregroundStyle(
            gameKitManager.errorMessage == nil
                ? .white.opacity(0.72)
                : Color.red.opacity(0.9)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func routeToPreferenceIfRoomIsActive() {
        guard gameKitManager.partyCode != nil else { return }

        var destination = NavigationPath()
        destination.append(Route.mechanicPreference)
        path = destination
    }

    private func endRoomSetup() {
        if gameKitManager.hasActiveRoom {
            gameKitManager.disconnect()
        }
        collectionLink = ""
        selectedMechanics.removeAll()
    }
}

#Preview {
    LobbyScreen(gameKitManager: .shared)
}
