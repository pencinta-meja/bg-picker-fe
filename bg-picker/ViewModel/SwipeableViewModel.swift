//
//  SwipeableViewModel.swift
//  bg-picker
//
//  Created by Danniel on 06/05/26.
//
import SwiftUI
import Combine

class SwipeableViewModel: ObservableObject {
    private var originalCards: [BoardGameCard]
    @Published var unswipedCards: [BoardGameCard]
    @Published var swipedCards: [BoardGameCard]
    
    init(cards: [BoardGameCard]) {
        self.originalCards = cards
        self.unswipedCards = cards.shuffled()
        self.swipedCards = []
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
