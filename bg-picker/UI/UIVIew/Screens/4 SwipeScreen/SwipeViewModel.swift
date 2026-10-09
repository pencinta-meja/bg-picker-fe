import Combine
import SwiftUI

final class SwipeViewModel: ObservableObject {
    private var originalCards: [BoardGameCard] = []
    @Published var unswipedCards: [BoardGameCard] = []
    @Published var swipedCards: [BoardGameCard] = []

    var canFinish: Bool { !originalCards.isEmpty && unswipedCards.isEmpty }

    init(cards: [BoardGameCard] = []) {
        setSession(cards: cards, progress: RoomSwipeProgress())
    }

    /// Applies the host's canonical order and restores the replicated local checkpoint.
    func setSession(cards: [BoardGameCard], progress: RoomSwipeProgress) {
        let expectedUnswipedIDs = cards.filter { progress.decisions[$0.id] == nil }.map(\.id)
        let expectedSwipedIDs = cards.filter { progress.decisions[$0.id] != nil }.map(\.id)
        guard originalCards.map(\.id) != cards.map(\.id)
                || unswipedCards.map(\.id) != expectedUnswipedIDs
                || swipedCards.map(\.id) != expectedSwipedIDs else { return }

        originalCards = cards
        swipedCards = cards.compactMap { card in
            guard let decision = progress.decisions[card.id] else { return nil }
            var restored = card
            restored.swipeDirection = decision == .accepted ? .right : .left
            return restored
        }
        unswipedCards = cards.filter { progress.decisions[$0.id] == nil }
    }

    func removeTopCard() {
        guard !unswipedCards.isEmpty else { return }
        swipedCards.append(unswipedCards.removeFirst())
    }

    func updateTopCardSwipeDirection(_ direction: BoardGameCard.SwipeDirection) {
        guard !unswipedCards.isEmpty else { return }
        unswipedCards[0].swipeDirection = direction
    }
}
