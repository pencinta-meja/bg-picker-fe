import SwiftUI

struct CreateRoomScreen: View {
    @ObservedObject var gameKitManager: GameKitManager
    @Binding var collectionLink: String

    @State private var hasAttemptedSubmission = false
    @FocusState private var linkFieldFocused: Bool

    var body: some View {
        AppBackground {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 180)

                        Text("Input Collection Link")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        collectionField
                            .padding(.top, 44)

                        validationMessage
                            .padding(.top, 14)

                        Spacer(minLength: 80)

                        PrimaryButton(title: "Create Room", action: createRoom)
                            .disabled(!canCreateRoom)
                            .padding(.bottom, 34)
                    }
                    .padding(.horizontal, 36)
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
            linkFieldFocused = collectionLink.isEmpty
        }
        .onChange(of: collectionLink) { _, _ in
            hasAttemptedSubmission = false
        }
    }

    private var collectionField: some View {
        HStack(spacing: 12) {
            TextField("BoardGameGeek collection URL", text: $collectionLink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textContentType(.URL)
                .submitLabel(.continue)
                .focused($linkFieldFocused)
                .onSubmit(createRoom)

            Image(systemName: validCollectionURL == nil
                ? "checkmark.circle"
                : "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(validCollectionURL == nil ? .white.opacity(0.35) : .green)
                .accessibilityHidden(true)
        }
        .font(.body)
        .foregroundStyle(.white)
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .frame(minHeight: 58)
        .background(.white.opacity(0.42), in: Capsule())
    }

    @ViewBuilder
    private var validationMessage: some View {
        if shouldShowURLValidationError {
            Label(
                "Enter a valid HTTPS BoardGameGeek URL.",
                systemImage: "exclamationmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(.red.opacity(0.92))
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let error = gameKitManager.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red.opacity(0.92))
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("The link stays on this device for the current room only.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var validCollectionURL: URL? {
        let trimmed = collectionLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              host == "boardgamegeek.com" || host.hasSuffix(".boardgamegeek.com"),
              let url = components.url else {
            return nil
        }
        return url
    }

    private var shouldShowURLValidationError: Bool {
        let hasInput = !collectionLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return validCollectionURL == nil && (hasAttemptedSubmission || hasInput)
    }

    private var canCreateRoom: Bool {
        validCollectionURL != nil
            && gameKitManager.isAuthenticated
            && gameKitManager.isActivityReady
            && !gameKitManager.hasActiveRoom
    }

    private func createRoom() {
        hasAttemptedSubmission = true
        guard let url = validCollectionURL, canCreateRoom else { return }

        linkFieldFocused = false
        collectionLink = url.absoluteString
        gameKitManager.createRoom()
    }
}

#Preview {
    NavigationStack {
        CreateRoomScreen(
            gameKitManager: .shared,
            collectionLink: .constant("")
        )
    }
}
