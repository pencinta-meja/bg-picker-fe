import SwiftUI

struct PodiumScreen: View {
    let room: any RoomSession

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)

                    Text("Room Results")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Based on \(room.finishedPlayerCount) finished \(room.finishedPlayerCount == 1 ? "player" : "players")")
                        .foregroundStyle(.white.opacity(0.72))

                    if room.hasPendingResults {
                        Label("New results are available. Pull to refresh.", systemImage: "arrow.clockwise")
                            .font(.footnote.bold())
                            .foregroundStyle(.yellow)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if room.resultGroups.isEmpty {
                        emptyResults
                    } else {
                        ForEach(room.resultGroups) { group in
                            PodiumCard(group: group)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .refreshable {
                room.refreshResults()
            }
        }
        .onAppear {
            room.refreshResults()
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack.badge.questionmark")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.5))

            Text(room.finishedPlayerCount == 0 ? "Nobody Has Finished Yet" : "No Games Accepted Yet")
                .font(.title3.bold())

            Text("Results use only players who have finished. Pull down when more players submit their choices.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 64)
    }
}

#if DEBUG
#Preview {
    PodiumScreen(room: PreviewRoomSession.started)
}
#endif
