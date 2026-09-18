//
//  SwipeableViewModel.swift
//  bg-picker
//
//  Created by Danniel on 06/05/26.
//
import SwiftUI
import Combine

final class SwipeViewModel: ObservableObject {
    private var originalCards: [BoardGameCard]
    @Published var unswipedCards: [BoardGameCard]
    @Published var swipedCards: [BoardGameCard]

    var canFinish: Bool {
        !swipedCards.isEmpty && unswipedCards.isEmpty
    }

    init(cards: [BoardGameCard] = []) {
        self.originalCards = cards
        self.unswipedCards = cards.shuffled()
        self.swipedCards = []
    }

    /// Cards arrive asynchronously once the geeklist finishes loading.
    ///
    /// Deliberately a no-op when the deck is unchanged, so re-rendering the screen
    /// does not reshuffle a deck the player is partway through.
    func setCards(_ cards: [BoardGameCard]) {
        guard originalCards.map(\.id) != cards.map(\.id) else { return }
        originalCards = cards
        unswipedCards = cards.shuffled()
        swipedCards = []
    }

    func removeTopCard() {
        if !unswipedCards.isEmpty {
            guard let card = unswipedCards.first else { return }
            unswipedCards.removeFirst()
            swipedCards.append(card)
        }
    }
    
    func updateTopCardSwipeDirection(_ direction: BoardGameCard.SwipeDirection) {
        if !unswipedCards.isEmpty {
            unswipedCards[0].swipeDirection = direction
        }
    }
    
    func reset() {
        unswipedCards = originalCards.shuffled()
        swipedCards = []
    }
}
