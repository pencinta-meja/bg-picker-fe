import SwiftUI

struct PreferenceScreen: View {
    let room: any RoomSession
    let router: AppRouter

    @State private var selectedGroups: Set<BoardGameCategoryGroup> = []

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 24) {
                    roomSummary

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BoardGameCategoryGroup.allCases) { group in
                            CategoryButton(
                                title: group.rawValue,
                                isSelected: selectedGroups.contains(group)
                            ) {
                                toggle(group)
                            }
                            .disabled(room.localIsReady || room.gamePhase == .started)
                        }
                    }

                    sessionStatus
                }
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .padding(.bottom, 170)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                actionArea
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.clear, Color(red: 0.28, green: 0, blue: 0.48).opacity(0.96)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: room.gamePhase, initial: true) { _, _ in
            routeForCurrentSession()
        }
        .onChange(of: room.localSwipeProgress.isFinished, initial: true) { _, _ in
            routeForCurrentSession()
        }
    }

    private var roomSummary: some View {
        HStack(spacing: 18) {
            Group {
                if let url = room.partyURL {
                    PartyQRCodeView(url: url)
                } else {
                    Image(systemName: "qrcode")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .foregroundStyle(.black.opacity(0.32))
                        .accessibilityLabel("Room QR code unavailable")
                }
            }
            .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 8) {
                Text(room.partyCode ?? "No room code")
                    .font(.title.bold())
                    .monospaced()
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Text(joinedPlayersText)
                    .font(.body)

                if room.isLocalHost {
                    Label("Host", systemImage: "crown.fill")
                        .font(.caption.bold())
                }
            }
            .foregroundStyle(.black)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.black, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var sessionStatus: some View {
        if let message = room.sessionError ?? room.errorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red.opacity(0.92))
        } else {
            HStack(spacing: 10) {
                if room.gamePhase == .synchronizing || room.matchState == .matchmaking {
                    ProgressView().tint(.white)
                }
                Text(statusText)
            }
            .foregroundStyle(.white.opacity(0.76))
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 12) {
            if room.gamePhase == .lockedOut || room.gamePhase == .failed {
                PrimaryButton(title: "Leave Room") {
                    router.popToLobby()
                }
            } else if !room.localIsReady {
                PrimaryButton(title: "Next") {
                    room.setReady(categories: selectedGroups)
                }
                .disabled(room.gamePhase == .started)
            } else if room.isLocalHost {
                PrimaryButton(title: "Start Game") {
                    room.startGame()
                }
                .disabled(!room.canStartGame)

                PrimaryButton(title: "Edit Preferences", style: .outlined) {
                    room.setNotReady()
                }
            } else {
                PrimaryButton(title: "Waiting for Host…") {}
                    .disabled(true)

                PrimaryButton(title: "Edit Preferences", style: .outlined) {
                    room.setNotReady()
                }
            }
        }
    }

    private var joinedPlayersText: String {
        let count = room.roomMemberCount
        return "\(count) \(count == 1 ? "Person" : "People") Joined"
    }

    private var statusText: String {
        switch room.gamePhase {
        case .idle, .waitingForPlayers:
            return "Waiting for at least one more player."
        case .synchronizing:
            return "Synchronizing the host’s geeklist…"
        case .waitingForReady:
            let ready = room.participants.filter(\.isReady).count
            return "\(ready) of \(room.participants.count) players ready."
        case .readyToStart:
            return room.isLocalHost ? "Everyone is ready. Start when you are ready." : "Everyone is ready. Waiting for the host."
        case .started:
            return "The game has started."
        case .lockedOut:
            return "This room has already started."
        case .failed:
            return "The room needs attention."
        }
    }

    private func toggle(_ group: BoardGameCategoryGroup) {
        if selectedGroups.contains(group) {
            selectedGroups.remove(group)
        } else {
            selectedGroups.insert(group)
        }
    }

    private func routeForCurrentSession() {
        guard room.gamePhase == .started else { return }
        if room.localSwipeProgress.isFinished {
            if !router.contains(.podium) { router.push(.podium) }
        } else if !router.contains(.swiping) {
            router.push(.swiping)
        }
    }
}

#if DEBUG
#Preview("Host ready") {
    NavigationStack {
        PreferenceScreen(room: PreviewRoomSession.hostReadyToStart, router: AppRouter())
    }
}

#Preview("Waiting") {
    NavigationStack {
        PreferenceScreen(room: PreviewRoomSession.waitingForPlayers, router: AppRouter())
    }
}

#Preview("Late join") {
    NavigationStack {
        PreferenceScreen(room: PreviewRoomSession.lateJoinLocked, router: AppRouter())
    }
}
#endif
