import Foundation

nonisolated struct BGGItem: Codable, Identifiable {
    let id: String
    let names: [BGGNameAttr]
    let description: String
    let yearPublished: BGGValueAttr?
    let minPlayers: BGGValueAttr?
    let maxPlayers: BGGValueAttr?
    let playingTime: BGGValueAttr?
    let minPlayTime: BGGValueAttr?
    let maxPlayTime: BGGValueAttr?
    let image: String?
    let thumbnail: String?
    /// Categories, mechanics, designers and more all arrive as `<link>` siblings;
    /// they are only told apart by their `type`.
    let links: [BGGLinkAttr]?
    /// Present only when the request was made with `stats=1`.
    let statistics: BGGStatistics?

    enum CodingKeys: String, CodingKey {
        case id
        case names = "name"
        case description
        case yearPublished = "yearpublished"
        case minPlayers = "minplayers"
        case maxPlayers = "maxplayers"
        case playingTime = "playingtime"
        case minPlayTime = "minplaytime"
        case maxPlayTime = "maxplaytime"
        case image
        case thumbnail
        case links = "link"
        case statistics
    }

    var primaryName: String {
        names.first(where: { $0.type == "primary" })?.value ?? names.first?.value ?? "Unknown"
    }

    /// BGG double-encodes some entities in the description field, so they show up
    /// as literal text (e.g. "&#10;") instead of being parsed as real characters.
    var cleanDescription: String {
        description
            .replacingOccurrences(of: "&#10;", with: "\n")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&rsquo;", with: "'")
            .replacingOccurrences(of: "&lsquo;", with: "'")
            .replacingOccurrences(of: "&mdash;", with: "\u{2014}")
            .replacingOccurrences(of: "&ldquo;", with: "\"")
            .replacingOccurrences(of: "&rdquo;", with: "\"")
    }

    // MARK: - Link lookups

    func linkValues(ofType type: String) -> [String] {
        (links ?? [])
            .filter { $0.type == type }
            .map(\.value)
    }

    var categories: [String] { linkValues(ofType: "boardgamecategory") }
    var mechanics: [String] { linkValues(ofType: "boardgamemechanic") }

    // MARK: - Statistics

    /// Community rating on a 1-10 scale. `nil` when unrated or fetched without `stats=1`.
    var averageRating: Double? { Self.positiveDouble(statistics?.ratings?.average) }

    /// Complexity ("weight") on a 1-5 scale. `nil` when unrated or fetched without `stats=1`.
    var averageWeight: Double? { Self.positiveDouble(statistics?.ratings?.averageWeight) }

    /// BGG reports "0" rather than omitting the field for games nobody has rated,
    /// so a zero here means "no data", not an actual score of zero.
    private static func positiveDouble(_ attr: BGGValueAttr?) -> Double? {
        guard let raw = attr?.value, let value = Double(raw), value > 0 else { return nil }
        return value
    }
}
