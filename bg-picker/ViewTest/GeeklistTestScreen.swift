//
//  GeeklistTestScreen.swift
//  bg-picker
//
//  DEBUG-only harness for the geeklist pipeline.
//
//  The real entry point (CreateRoomScreen) sits behind Game Center authentication,
//  which not every contributor can complete — separate Individual Apple Developer
//  accounts mean only the owner of the App ID can sign in. This screen reaches the
//  same SessionGameStore and SwipeScreen without GameKit involved at all.
//
//  It owns a private store rather than using `.shared`, so debug loads never leak
//  into a real room — and it exercises the injection seam on SwipeScreen.
//

#if DEBUG
import SwiftUI

struct GeeklistTestScreen: View {
    /// A small public list (2 board games) — quick to load while iterating.
    /// Override at launch with `-GeeklistID 100`; Foundation folds launch
    /// arguments of that shape straight into UserDefaults.
    @State private var input = UserDefaults.standard.string(forKey: "GeeklistID") ?? "331207"
    @State private var path = NavigationPath()
    @StateObject private var store = SessionGameStore()
    /// `-GeeklistDeck` jumps straight to the real swipe UI once loading finishes.
    @State private var showDeck = false

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Geeklist test")
                        .font(.title2.bold())

                    TextField("Geeklist id or URL", text: $input)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 12) {
                        Button("Load") {
                            if !store.load(fromInput: input) {
                                // Mirrors what CreateRoomScreen's validation rejects.
                                input = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") { store.clear() }
                            .buttonStyle(.bordered)
                    }

                    stateSummary

                    if !store.cards.isEmpty {
                        Button("Open swipe deck") { showDeck = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(24)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .navigationDestination(isPresented: $showDeck) {
            SwipeScreen(path: $path, store: store)
        }
        .onChange(of: store.cards) { _, cards in
            if !cards.isEmpty, ProcessInfo.processInfo.arguments.contains("-GeeklistDeck") {
                showDeck = true
            }
        }
        .task {
            // Opening this screen means you want to test the pipeline, so run it.
            if case .idle = store.state {
                store.load(fromInput: input)
            }
        }
    }

    @ViewBuilder
    private var stateSummary: some View {
        switch store.state {
        case .idle:
            Text("Idle.")
        case .loading:
            HStack(spacing: 10) {
                ProgressView().tint(.white)
                Text("Loading…")
            }
        case .failed(let message):
            Text(message)
                .foregroundStyle(.red.opacity(0.9))
        case .loaded where store.cards.isEmpty:
            Text("Loaded, but the list had no board games.")
        case .loaded:
            VStack(alignment: .leading, spacing: 14) {
                Text("Loaded \(store.cards.count) game(s)")
                    .font(.headline)

                // Printing the mapped values is the whole point — it shows at a glance
                // whether stats=1 actually came through.
                ForEach(store.cards) { card in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(card.title).font(.subheadline.bold())
                        Text(card.categoriesText)
                        Text("\(card.playersText) · \(card.playTimeText)")
                        Text("Complexity \(card.complexityText) · Rating \(card.ratingText)")
                        Text(card.thumbnailURL?.absoluteString ?? "no thumbnail")
                            .lineLimit(1)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .font(.caption)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GeeklistTestScreen()
    }
}
#endif
