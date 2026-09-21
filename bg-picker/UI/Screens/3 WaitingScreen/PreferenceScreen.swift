import SwiftUI

struct PreferenceScreen: View {
    let room: any RoomSession
    @Binding var selectedGroups: Set<BoardGameCategoryGroup>
    @Binding var path: NavigationPath

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
                        }
                    }

                    if let error = room.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.92))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if room.matchState == .matchmaking {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text(room.statusMessage)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Next") {
                    path.append(Route.swiping)
                }
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
                    .font(.title)
                    .fontWeight(.bold)
                    .monospaced()
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Text(joinedPlayersText)
                    .font(.body)
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

    private var joinedPlayersText: String {
        let count = room.roomMemberCount
        return "\(count) \(count == 1 ? "Person" : "People") Joined"
    }

    private func toggle(_ group: BoardGameCategoryGroup) {
        if selectedGroups.contains(group) {
            selectedGroups.remove(group)
        } else {
            selectedGroups.insert(group)
        }
    }
}

#if DEBUG
#Preview("Waiting for players") {
    NavigationStack {
        PreferenceScreen(
            room: PreviewRoomSession.waitingForPlayers,
            selectedGroups: .constant([.fantasyAndSciFi, .partyAndPopCulture]),
            path: .constant(NavigationPath())
        )
    }
}

#Preview("No room yet") {
    NavigationStack {
        PreferenceScreen(
            room: PreviewRoomSession.ready,
            selectedGroups: .constant([]),
            path: .constant(NavigationPath())
        )
    }
}
#endif
