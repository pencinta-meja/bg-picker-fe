import Foundation

nonisolated struct BGGItem: Codable, Identifiable {
    let id: String
    let names: [BGGNameAttr]
    let description: String
    let yearPublished: BGGValueAttr?
    let minPlayers: BGGValueAttr?
    let maxPlayers: BGGValueAttr?
    let playingTime: BGGValueAttr?
    let image: String?
    let thumbnail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case names = "name"
        case description
        case yearPublished = "yearpublished"
        case minPlayers = "minplayers"
        case maxPlayers = "maxplayers"
        case playingTime = "playingtime"
        case image
        case thumbnail
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
}

