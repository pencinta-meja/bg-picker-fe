import GameKit
import SwiftUI
import UIKit

struct GameKitTestScreen: View {
    @ObservedObject var manager: GameKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var roomCode = ""
    @State private var message = ""
    @FocusState private var codeFieldFocused: Bool

    let startsInJoinMode: Bool

    init(manager: GameKitManager, startsInJoinMode: Bool = false) {
        self.manager = manager
        self.startsInJoinMode = startsInJoinMode
    }

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.08), .black.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header

                    if manager.partyCode == nil {
                        joinCard
                    } else {
                        activeRoomContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if startsInJoinMode, manager.partyCode == nil {
                codeFieldFocused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                leaveAndDismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.16), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(manager.partyCode == nil ? "Join a Room" : "Room Console")
                    .font(.title2.bold())
                Text(manager.playerName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            statusBadge
        }
        .foregroundStyle(.white)
        .padding(.top, 12)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(manager.matchState.rawValue)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.black.opacity(0.18), in: Capsule())
    }

    private var joinCard: some View {
        VStack(spacing: 22) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.white.opacity(0.88))

            VStack(spacing: 8) {
                Text("Enter the room code")
                    .font(.title3.bold())
                Text("Ask the host for the six-character Game Center code.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            TextField("ABC-DEF", text: $roomCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .multilineTextAlignment(.center)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .tracking(5)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                }
                .focused($codeFieldFocused)
                .submitLabel(.join)
                .onSubmit(joinRoom)
                .onChange(of: roomCode) { _, newValue in
                    let normalized = GameKitManager.normalizePartyCodeInput(newValue)
                    if normalized != newValue {
                        roomCode = normalized
                    }
                }

            Button(action: joinRoom) {
                Label("Join Room", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("PrimaryButton"), in: Capsule())
            }
            .disabled(roomCode.count != 7 || !manager.isActivityReady)
            .opacity(roomCode.count == 7 && manager.isActivityReady ? 1 : 0.55)

            if let error = manager.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Label(
                "QR invitations open through the iPhone Camera app.",
                systemImage: "camera.viewfinder"
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.55))
        }
        .foregroundStyle(.white)
        .padding(24)
        .glassCard()
    }

    @ViewBuilder
    private var activeRoomContent: some View {
        if manager.roomRole == .host {
            invitationCard
        }

        roomStatusCard
        messageConsole
    }

    private var invitationCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 5) {
                Text("ROOM CODE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
                Text(manager.partyCode ?? "")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .tracking(4)
            }

            if let url = manager.partyURL {
                PartyQRCodeView(url: url)
                    .frame(width: 210, height: 210)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22))
            } else {
                Label("Game Center did not provide a party URL.", systemImage: "qrcode")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = manager.partyCode
                } label: {
                    Label("Copy code", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoomSecondaryButtonStyle())

                if let url = manager.partyURL {
                    ShareLink(item: url) {
                        Label("Share link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoomSecondaryButtonStyle())
                }
            }

            Text("Friends can enter the code in this app or scan the QR with their Camera.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(22)
        .glassCard()
    }

    private var roomStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(manager.roomRole == .host ? "Your room" : "Joined room")
                        .font(.headline)
                    Text(manager.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                if manager.matchState == .matchmaking {
                    ProgressView()
                        .tint(.white)
                }
            }

            Divider().overlay(.white.opacity(0.14))

            playerRow(name: manager.playerName, label: "You")

            ForEach(manager.players, id: \.gamePlayerID) { player in
                playerRow(name: player.displayName, label: "Connected")
            }

            if manager.players.isEmpty {
                Label("Waiting for another player", systemImage: "person.crop.circle.badge.clock")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))
            }

            if let error = manager.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .glassCard()
    }

    private var messageConsole: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reliable message test", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("Message all players", text: $message)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    .submitLabel(.send)
                    .onSubmit(sendMessage)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .frame(width: 44, height: 44)
                        .background(Color("PrimaryButton"), in: Circle())
                        .foregroundStyle(.black.opacity(0.8))
                }
                .disabled(!canSendMessage)
                .opacity(canSendMessage ? 1 : 0.5)
            }

            if manager.receivedPackets.isEmpty {
                Text("Received messages will appear here.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                ForEach(manager.receivedPackets) { received in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(received.sender.displayName)
                                .font(.caption.bold())
                            Spacer()
                            Text(received.packet.sentAt, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.45))
                        }

                        if let text = try? received.packet.decode(String.self) {
                            Text(text)
                        } else {
                            Text("\(received.packet.payload.count) bytes")
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                    .padding(12)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                Button("Clear received messages", role: .destructive) {
                    manager.clearReceivedPackets()
                }
                .font(.footnote)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .glassCard()
    }

    private var statusColor: Color {
        switch manager.matchState {
        case .connected, .ready:
            return .green
        case .matchmaking, .loadingActivity:
            return .yellow
        case .failed:
            return .red
        case .idle:
            return .gray
        }
    }

    private var canSendMessage: Bool {
        !manager.players.isEmpty
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func playerRow(name: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.72))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func joinRoom() {
        codeFieldFocused = false
        manager.joinRoom(code: roomCode)
    }

    private func sendMessage() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manager.send(trimmed, type: "test.text")
        message = ""
    }

    private func leaveAndDismiss() {
        if manager.hasActiveRoom {
            manager.disconnect()
        }
        dismiss()
    }
}

private struct RoomSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(.white.opacity(configuration.isPressed ? 0.2 : 0.12), in: Capsule())
    }
}

private extension View {
    func glassCard() -> some View {
        background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
    }
}

#Preview {
    GameKitTestScreen(manager: .shared, startsInJoinMode: true)
}
