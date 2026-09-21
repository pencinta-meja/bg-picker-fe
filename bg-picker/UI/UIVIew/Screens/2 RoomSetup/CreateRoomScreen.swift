import SwiftUI

struct CreateRoomScreen: View {
    let room: any RoomSession
    let router: AppRouter
    @ObservedObject var store: SessionGameStore = .shared

    @State private var geeklistLink = ""
    @State private var hasAttemptedSubmission = false
    @FocusState private var linkFieldFocused: Bool

    var body: some View {
        AppBackground {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 180)

                        Text("Input Geeklist Link")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        geeklistField
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
            linkFieldFocused = geeklistLink.isEmpty
        }
        .onChange(of: geeklistLink) { _, _ in
            hasAttemptedSubmission = false
        }
        // This screen asked for the room, so this screen routes to it.
        .onChange(of: room.partyCode) { _, code in
            if code != nil {
                router.push(.categoryPreference)
            }
        }
    }

    private var geeklistField: some View {
        HStack(spacing: 12) {
            TextField("BoardGameGeek geeklist URL", text: $geeklistLink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textContentType(.URL)
                .submitLabel(.continue)
                .focused($linkFieldFocused)
                .onSubmit(createRoom)

            Image(systemName: validGeeklistURL == nil
                ? "checkmark.circle"
                : "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(validGeeklistURL == nil ? .white.opacity(0.35) : .green)
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
                "Enter a BoardGameGeek geeklist URL, e.g. boardgamegeek.com/geeklist/331207",
                systemImage: "exclamationmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(.red.opacity(0.92))
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let error = room.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red.opacity(0.92))
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if !room.isAuthenticated || !room.isActivityReady {
            HStack(spacing: 8) {
                if room.matchState == .loadingActivity {
                    ProgressView()
                        .tint(.white)
                }
                Text(room.statusMessage)
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

    private var validGeeklistURL: URL? {
        let trimmed = geeklistLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              host == "boardgamegeek.com" || host.hasSuffix(".boardgamegeek.com"),
              let url = components.url,
              BGGService.geeklistID(from: url) != nil else {
            return nil
        }
        return url
    }

    private var shouldShowURLValidationError: Bool {
        let hasInput = !geeklistLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return validGeeklistURL == nil && (hasAttemptedSubmission || hasInput)
    }

    private var canCreateRoom: Bool {
        validGeeklistURL != nil
            && room.isAuthenticated
            && room.isActivityReady
            && !room.hasActiveRoom
    }

    private func createRoom() {
        hasAttemptedSubmission = true
        guard let url = validGeeklistURL,
              let listID = BGGService.geeklistID(from: url),
              canCreateRoom else { return }

        linkFieldFocused = false
        geeklistLink = url.absoluteString
        store.load(geeklistID: listID)
        room.createRoom()
    }
}

#if DEBUG
#Preview("Ready") {
    NavigationStack {
        CreateRoomScreen(
            room: PreviewRoomSession.ready,
            router: AppRouter(),
            store: SessionGameStore()
        )
    }
}

#Preview("Loading activity") {
    NavigationStack {
        CreateRoomScreen(
            room: PreviewRoomSession.loadingActivity,
            router: AppRouter(),
            store: SessionGameStore()
        )
    }
}
#endif
