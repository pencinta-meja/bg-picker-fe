//
//  BoardGameCard.swift
//  bg-picker
//

import Foundation
import UIKit

struct BoardGameCard: Identifiable, Equatable {
    enum SwipeDirection {
        case left, right, none
    }

    let id: String
    let title: String
    let description: String
    let thumbnailURL: URL?
    let gameplayImageURL: URL?
    let thumbnailLocalImage: UIImage?   // for user-added games with local photos
    let gameplayLocalImage: UIImage?
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
        self.categoriesText = ""
        self.playTimeText = "\(boardgame.minDuration) - \(boardgame.maxDuration) minutes"
        self.playersText = "\(boardgame.minPlayers) - \(boardgame.maxPlayers) players"
        self.complexityText = "\(boardgame.complexity)"
        self.ratingText = ""

        let coverPath = boardgame.cover_image_path
        let gameplayPath = boardgame.gameplay_image_path

        if coverPath.hasPrefix("http") {
            self.thumbnailURL = URL(string: coverPath)
            self.thumbnailLocalImage = nil
        } else {
            self.thumbnailURL = nil
            self.thumbnailLocalImage = UIImage(contentsOfFile: coverPath)
        }

        if gameplayPath.hasPrefix("http") {
            self.gameplayImageURL = URL(string: gameplayPath)
            self.gameplayLocalImage = nil
        } else {
            self.gameplayImageURL = nil
            self.gameplayLocalImage = UIImage(contentsOfFile: gameplayPath)
        }
    }

    static func == (lhs: BoardGameCard, rhs: BoardGameCard) -> Bool {
        lhs.id == rhs.id
    }
}
