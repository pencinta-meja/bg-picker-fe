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
    
    func finishRoom(completion: @escaping () -> ()) {
        // Skipping network call for now — use dummy room result
        let dummyRoom = RoomDto(id: "dummy-room-id", host: UserDto(id: "dummy-user-id", name: "Das"), code: "TEST123", numPlayer: 1, maxDuration: 120, status: .waiting, resultBoardgameIds: [])
        let dummyResults: [RoomResultDto] = [
            RoomResultDto(id: "1", room: dummyRoom, boardgame: BoardgameDto(id: "1", name: "Catan", cover_image_path: "https://cf.geekdo-images.com/0XODRpReiZBFUffEcqT5-Q__imagepage/img/enC7UTvCAnb6j1Uazvh0OBQjvxw=/fit-in/900x600/filters:no_upscale():strip_icc()/pic9156909.png", gameplay_image_path: "https://cf.geekdo-images.com/XTHTTzVKK0VrJMk5nQmhIw__imagepage@2x/img/5sL_ZXGnjzG1z9aEhib-yAS_UCM=/fit-in/1800x1200/filters:strip_icc()/pic9141778.jpg", description: "Strategy game for trading, building, and settling the island of Catan.", complexity: Float(4.6), minPlayers: 3, maxPlayers: 4, minDuration: 60, maxDuration: 120), numLikes: 5, initials: "CT"),
            RoomResultDto(id: "2", room: dummyRoom, boardgame: BoardgameDto(id: "5", name: "Hanabi", cover_image_path: "https://cf.geekdo-images.com/JDVksMwfcqoem1k_xtZrOA__itemrep@2x/img/LyLpjMu9OT3JXpx6wSMp5hlG7yg=/fit-in/492x600/filters:strip_icc()/pic2007286.jpg", gameplay_image_path: "https://cf.geekdo-images.com/imKe2sGj7pOjVWkwCBBmpA__imagepage@2x/img/XfwzyuUFipQie4lxNz8AN4dn_LA=/fit-in/1800x1200/filters:strip_icc()/pic2023758.jpg", description: "Cooperative deduction game where you only see other players' cards.", complexity: Float(3.4), minPlayers: 2, maxPlayers: 5, minDuration: 25, maxDuration: 25), numLikes: 3, initials: "HB")
        ]
        RoomManager.shared.saveRoomResult(result: dummyResults)
        completion()
    }
}
