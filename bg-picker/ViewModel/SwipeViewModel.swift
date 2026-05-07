//
//  SwipeableViewModel.swift
//  bg-picker
//
//  Created by Danniel on 06/05/26.
//
import SwiftUI
import Combine

class SwipeViewModel: ObservableObject {
    @ObservedObject private var networkManager = NetworkManager.shared
    private var originalCards: [BoardGameCard]
    @Published var unswipedCards: [BoardGameCard]
    @Published var swipedCards: [BoardGameCard]
    
    init() {
        let boardgameDtos = SwipeManager.shared.getSwipeList() ?? []
        self.originalCards = boardgameDtos.map { BoardGameCard(boardgame: $0) }
        self.unswipedCards = self.originalCards.shuffled()
        self.swipedCards = []
    }
    
    func removeTopCard() {
        if !unswipedCards.isEmpty {
            guard let card = unswipedCards.first else { return }
            unswipedCards.removeFirst()
            swipedCards.append(card)
            
            swipeBoardgame(boardgameId: card.id, isLike: card.swipeDirection == .right)
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
    
    func swipeBoardgame(boardgameId: String, isLike: Bool) {
        guard let userId = UserManager.shared.id, let roomId = RoomManager.shared.id else {
            print("User ID or Room ID is missing")
            return
        }
        
        let payload: [String: Any] = [
            "boardgameId": boardgameId,
            "isLike": isLike
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            return
        }
        
        let endpoint = "http://187.77.115.63/user/\(userId)/room/\(roomId)/swipe"
        
        networkManager.post(endpoint: endpoint, payload: payloadData) { (response: SwipeBoardgameResponseDto?) in
            if let response = response {
                print("Swipe data posted successfully: \(response)")
            } else {
                print("Failed to post swipe data")
            }
        }
    }

}
