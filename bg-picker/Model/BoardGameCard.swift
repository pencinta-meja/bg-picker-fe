//
//  BoardGameCard.swift
//  bg-picker
//

import Foundation

struct BoardGameCard: Identifiable, Equatable {
    enum SwipeDirection {
        case left, right, none
    }

    let id = UUID()
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
}
