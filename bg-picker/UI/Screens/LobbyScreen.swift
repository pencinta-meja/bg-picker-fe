import SwiftUI

struct LobbyScreen: View {
    @ObservedObject var gameKitManager: GameKitManager
    @State private var showRoomConsole = false
    @State private var startInJoinMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.black.opacity(0.08), .black.opacity(0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 48)
                        hero
                        readinessCard
                        roomActions
                        setupFootnote
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $showRoomConsole) {
                GameKitTestScreen(
                    manager: gameKitManager,
                    startsInJoinMode: startInJoinMode
                )
            }
            .onChange(of: gameKitManager.partyCode) { _, newCode in
                if newCode != nil, !showRoomConsole {
                    startInJoinMode = false
                    showRoomConsole = true
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                .font(.system(size: 64, weight: .light))
                .symbolRenderingMode(.hierarchical)

            Text("Ready When You Are")
                .font(.largeTitle.bold())

            Text("Create a private Game Center room, then invite friends with a code or QR link.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .foregroundStyle(.white)
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: readinessIcon)
                    .font(.title3)
                    .foregroundStyle(readinessColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(gameKitManager.playerName)
                        .font(.headline)
                    Text(gameKitManager.matchState.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                if gameKitManager.matchState == .loadingActivity {
                    ProgressView()
                        .tint(.white)
                }
            }

            Text(gameKitManager.statusMessage)
                .font(.footnote)
                .foregroundStyle(
                    gameKitManager.errorMessage == nil
                        ? .white.opacity(0.72)
                        : Color.red.opacity(0.9)
                )

            if !gameKitManager.isAuthenticated {
                Button("Sign in to Game Center") {
                    gameKitManager.authenticate()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryButton"))
                .foregroundStyle(.black.opacity(0.78))
            } else if !gameKitManager.isActivityReady,
                      gameKitManager.matchState != .loadingActivity {
                Button("Retry room configuration") {
                    gameKitManager.authenticate()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var roomActions: some View {
        HStack(spacing: 14) {
            roomButton(
                title: "Create Room",
                subtitle: "Get a code & QR",
                systemImage: "qrcode",
                enabled: canStartRoom
            ) {
                startInJoinMode = false
                gameKitManager.createRoom()
            }

            roomButton(
                title: "Join Room",
                subtitle: "Enter a code",
                systemImage: "person.2.fill",
                enabled: canStartRoom
            ) {
                startInJoinMode = true
                showRoomConsole = true
            }
        }
    }

    private var setupFootnote: some View {
        Label(
            "Requires the board-game-room activity in App Store Connect.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(.white.opacity(0.55))
        .multilineTextAlignment(.center)
    }

    private var canStartRoom: Bool {
        gameKitManager.isAuthenticated
            && gameKitManager.isActivityReady
            && !gameKitManager.hasActiveRoom
    }

    private var readinessIcon: String {
        if gameKitManager.errorMessage != nil { return "exclamationmark.triangle.fill" }
        if gameKitManager.isActivityReady { return "checkmark.circle.fill" }
        return "gamecontroller.fill"
    }

    private var readinessColor: Color {
        if gameKitManager.errorMessage != nil { return .red }
        if gameKitManager.isActivityReady { return .green }
        return .white.opacity(0.7)
    }

    private func roomButton(
        title: String,
        subtitle: String,
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .semibold))
                Spacer()
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 126)
            .padding(18)
            .background(
                enabled ? .white.opacity(0.16) : .white.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(enabled ? 0.24 : 0.1), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.62)
    }
}

#Preview {
    LobbyScreen(gameKitManager: .shared)
}
