//
//  ContentView.swift
//  bg-picker
//
//  Created by Danniel on 02/05/26.
//

import SwiftUI

struct SwipeScreen: View {
    @Binding var path: NavigationPath
    // Defaulted rather than required: no prop-drilling, but previews and the debug
    // harness can still inject an isolated store.
    @ObservedObject var store: SessionGameStore = .shared

    // @StateObject, not @ObservedObject: this view owns the deck. An @ObservedObject
    // initialised inline is re-created whenever SwiftUI re-inits the view, which
    // silently throws away swipe progress.
    @StateObject private var viewModel = SwipeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Room")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 70)

                Spacer(minLength: 8)

                content
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: 560)

                Spacer(minLength: 32)

                Button(action: finishSwiping) {
                    Text("Finish")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(red: 0.93, green: 0.88, blue: 0.99))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.canFinish)
                .opacity(viewModel.canFinish ? 1 : 0.55)
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
        .onAppear { syncDeck() }
        .onChange(of: store.cards) { _, _ in syncDeck() }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            statusView {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Loading games from the geeklist…")
            }

        case .failed(let message):
            statusView {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red.opacity(0.9))
                Text(message)
            }

        case .loaded where store.cards.isEmpty:
            statusView {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                Text("That geeklist has no board games in it.")
            }

        case .loaded:
            SwipeableCardsView(swipeableViewModel: viewModel) { _ in
                finishSwiping()
            }
        }
    }

    private func statusView<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 16) {
            content()
        }
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(0.85))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func syncDeck() {
        viewModel.setCards(store.cards)
    }

    private func finishSwiping() {
        guard viewModel.canFinish else { return }
        path.append(Route.podium)
    }
}

#Preview {
    SwipeScreen(path: .constant(NavigationPath()), store: SessionGameStore())
}
