import SwiftUI

struct JoinRoomScreen: View {
    @ObservedObject var gameKitManager: GameKitManager

    @State private var roomCode = ""
    @State private var hasAttemptedSubmission = false
    @FocusState private var codeFieldFocused: Bool

    var body: some View {
        AppBackground {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 170)

                        Text("Input Room Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Code can be received from Host")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.top, 8)

                        PartyCodeField(
                            code: $roomCode,
                            isFocused: $codeFieldFocused,
                            onSubmit: joinRoom
                        )
                        .padding(.top, 28)

                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .frame(width: 88, height: 88)
                            .background(.white.opacity(0.36), in: RoundedRectangle(cornerRadius: 26))
                            .padding(.top, 38)
                            .accessibilityLabel("QR joining is not available yet")

                        validationMessage
                            .padding(.top, 18)

                        Spacer(minLength: 72)

                        PrimaryButton(title: "Join Room", action: joinRoom)
                            .disabled(!canJoinRoom)
                            .padding(.bottom, 34)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            codeFieldFocused = true
        }
        .onChange(of: roomCode) { _, newValue in
            let normalized = GameKitManager.normalizePartyCodeInput(newValue)
            if normalized != newValue {
                roomCode = normalized
            }
            hasAttemptedSubmission = false
        }
    }

    @ViewBuilder
    private var validationMessage: some View {
        if hasAttemptedSubmission, roomCode.count != 7 {
            Label("Enter all six characters from the host.", systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red.opacity(0.92))
        } else if let error = gameKitManager.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red.opacity(0.92))
        } else if !gameKitManager.isAuthenticated || !gameKitManager.isActivityReady {
            HStack(spacing: 8) {
                if gameKitManager.matchState == .loadingActivity {
                    ProgressView()
                        .tint(.white)
                }
                Text(gameKitManager.statusMessage)
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.7))
        } else {
            Text("Enter the code without the dash; it will be added automatically.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var canJoinRoom: Bool {
        roomCode.count == 7
            && gameKitManager.isAuthenticated
            && gameKitManager.isActivityReady
            && !gameKitManager.hasActiveRoom
    }

    private func joinRoom() {
        hasAttemptedSubmission = true
        guard canJoinRoom else { return }

        codeFieldFocused = false
        gameKitManager.joinRoom(code: roomCode)
    }
}

private struct PartyCodeField: View {
    @Binding var code: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    private var characters: [Character] {
        Array(code.filter { $0.isLetter || $0.isNumber })
    }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Text(character(at: index))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospaced()
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            .white.opacity(index == characters.count && isFocused ? 0.58 : 0.42),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
            }

            TextField("", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .textContentType(.oneTimeCode)
                .submitLabel(.join)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .onSubmit(onSubmit)
                .accessibilityLabel("Six-character room code")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }

    private func character(at index: Int) -> String {
        guard characters.indices.contains(index) else { return "" }
        return String(characters[index])
    }
}

#Preview {
    NavigationStack {
        JoinRoomScreen(gameKitManager: .shared)
    }
}
