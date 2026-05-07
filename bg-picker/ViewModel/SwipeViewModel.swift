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
        guard let roomId = RoomManager.shared.id else {
            print("Room ID is missing")
            return
        }

        let payload: [String: Any] = [
            "userId": UserManager.shared.id!,
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            return
        }
        
        if RoomManager.shared.isHost == true {
            let endpoint = "http://187.77.115.63/room/\(roomId)/finish"
            networkManager.post(endpoint: endpoint, payload: payloadData) { (response: FinishRoomResponseDto?) in
                DispatchQueue.main.async {
                    if let response = response {
                        print("ROOM ID \(roomId)")
                        print("USER ID \(UserManager.shared.id!)")
                        RoomManager.shared.saveRoomResult(result: response.roomResults)
                        print("Room finished successfully: \(response)")
                        completion()
                    } else {
                        print("Failed to finish the room")
                    }
                }
            }
        } else {
            let endpoint = "http://187.77.115.63/room/\(roomId)/result"
            networkManager.get(endpoint: endpoint) { (response: FinishRoomResponseDto?) in
                DispatchQueue.main.async {
                    if let response = response {
                        RoomManager.shared.saveRoomResult(result: response.roomResults)
                        print("Room result fetched successfully: \(response)")
                        completion()
                    } else {
                        print("Failed to fetch room result")
                    }
                }
            }
        }
    }
}
