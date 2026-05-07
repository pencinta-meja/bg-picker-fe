//
//  BoardGameCard.swift
//  bg-picker
//

import Foundation

struct BoardGameCard: Identifiable, Equatable {
    enum SwipeDirection {
        case left, right, none
    }

    let id: String
    let title: String
    let description: String
    let thumbnailURL: URL?
    let gameplayImageURL: URL?
    let categoriesText: String
    let playTimeText: String
    let playersText: String
    let complexityText: String
    let ratingText: String
    var swipeDirection: SwipeDirection = .none
    
    init(boardgame: BoardgameDto) {
        self.id = boardgame.id
        self.title = boardgame.name
        self.description = boardgame.description
        self.thumbnailURL = URL(string: boardgame.cover_image_path)
        self.gameplayImageURL = URL(string: boardgame.gameplay_image_path)
        self.categoriesText = ""
        self.playTimeText = "\(boardgame.minDuration) - \(boardgame.maxDuration) minutes"
        self.playersText = "\(boardgame.minPlayers) - \(boardgame.maxPlayers) players"
        self.complexityText = "\(boardgame.complexity)"
        self.ratingText = ""
    }
}
