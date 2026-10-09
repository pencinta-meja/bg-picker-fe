import SwiftUI

struct SwipeScreen: View {
    let room: any RoomSession
    let router: AppRouter

    @StateObject private var viewModel = SwipeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 70)

                Spacer(minLength: 8)

                content
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: 560)

                Spacer(minLength: 32)

                Button(action: finishSwiping) {
                    Text(room.localSwipeProgress.isFinished ? "Submitted" : "Finish")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(red: 0.93, green: 0.88, blue: 0.99))
                        .clipShape(Capsule())
                }
                .disabled(!room.canFinishSwiping)
                .opacity(room.canFinishSwiping ? 1 : 0.55)
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
        .onAppear { syncDeck() }
        .onChange(of: room.canonicalDeck) { _, _ in syncDeck() }
        .onChange(of: room.localSwipeProgress) { _, _ in syncDeck() }
        .onChange(of: room.localSwipeProgress.isFinished) { _, finished in
            if finished, !router.contains(.podium) {
                router.push(.podium)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Game Room")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("\(room.participants.count) players • \(room.localSwipeProgress.decisions.count)/\(room.canonicalDeck.count) decided")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var content: some View {
        if let message = room.sessionError {
            statusView {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red.opacity(0.9))
                Text(message)
            }
        } else if room.gamePhase != .started || room.canonicalDeck.isEmpty {
            statusView {
                ProgressView().tint(.white).scaleEffect(1.4)
                Text("Synchronizing the room’s game deck…")
            }
        } else if room.localSwipeProgress.isFinished {
            statusView {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                Text("Your choices are submitted and cannot be changed.")
            }
        } else {
            SwipeableCardsView(swipeableViewModel: viewModel) { gameID, direction in
                room.recordDecision(gameID: gameID, accepted: direction == .right)
            }
        }
    }

    private func statusView<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 16) { content() }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func syncDeck() {
        viewModel.setSession(cards: room.canonicalDeck, progress: room.localSwipeProgress)
    }

    private func finishSwiping() {
        guard room.canFinishSwiping else { return }
        room.finishSwiping()
        if room.localSwipeProgress.isFinished, !router.contains(.podium) {
            router.push(.podium)
        }
    }
}

#if DEBUG
#Preview {
    SwipeScreen(room: PreviewRoomSession.started, router: AppRouter())
}
#endif
