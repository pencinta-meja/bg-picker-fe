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

    static func == (lhs: BoardGameCard, rhs: BoardGameCard) -> Bool {
        lhs.id == rhs.id
    }
}
