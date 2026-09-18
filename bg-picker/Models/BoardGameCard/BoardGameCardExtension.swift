//
//  BoardGameCard+BGGItem.swift
//  bg-picker
//
//  Turns a decoded /thing item into the presentation values the cards display.
//

import Foundation

extension BoardGameCard {
    /// Shown wherever BGG returned nothing. An honest dash beats a fabricated zero.
    static let missingValue = "—"

    init(item: BGGItem) {
        self.id = item.id
        self.title = item.primaryName
        self.description = item.cleanDescription
        self.thumbnailURL = item.thumbnail.flatMap { URL(string: $0) }
        self.gameplayImageURL = item.image.flatMap { URL(string: $0) }
        self.thumbnailLocalImage = nil
        self.gameplayLocalImage = nil
        self.categoriesText = Self.categoriesText(for: item)
        self.playTimeText = Self.playTimeText(for: item)
        self.playersText = Self.playersText(for: item)
        self.complexityText = Self.complexityText(for: item)
        self.ratingText = Self.ratingText(for: item)
    }

    // MARK: - Formatting

    private static func categoriesText(for item: BGGItem) -> String {
        let categories = item.categoryNames.prefix(3)
        return categories.isEmpty ? missingValue : categories.joined(separator: ", ")
    }

    private static func playersText(for item: BGGItem) -> String {
        switch (positiveInt(item.minPlayers), positiveInt(item.maxPlayers)) {
        case let (min?, max?) where min == max:
            return min == 1 ? "1 player" : "\(min) players"
        case let (min?, max?):
            return "\(min)–\(max) players"
        case let (min?, nil):
            return "\(min)+ players"
        case let (nil, max?):
            return "Up to \(max) players"
        case (nil, nil):
            return missingValue
        }
    }

    private static func playTimeText(for item: BGGItem) -> String {
        let min = positiveInt(item.minPlayTime)
        let max = positiveInt(item.maxPlayTime)

        if let min, let max {
            return min == max ? "\(min) min" : "\(min)–\(max) min"
        }
        // Older entries only carry the single `playingtime` field.
        if let single = min ?? max ?? positiveInt(item.playingTime) {
            return "\(single) min"
        }
        return missingValue
    }

    /// BGG's `averageweight` is already on a 1-5 scale, so it is shown against that
    /// scale rather than rescaled.
    private static func complexityText(for item: BGGItem) -> String {
        guard let weight = item.averageWeight else { return missingValue }
        return String(format: "%.1f / 5", weight)
    }

    private static func ratingText(for item: BGGItem) -> String {
        guard let rating = item.averageRating else { return missingValue }
        return String(format: "%.1f / 10", rating)
    }

    /// BGG uses "0" to mean "unknown" for player counts and durations.
    private static func positiveInt(_ attr: BGGValueAttr?) -> Int? {
        guard let raw = attr?.value, let value = Int(raw), value > 0 else { return nil }
        return value
    }
}
