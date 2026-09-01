//
//  BGGValueAttr.swift
//  bg-picker
//
//  Created by Danniel on 02/09/26.
//


//
//  BGGModels.swift
//  bggAPI-with-swift
//
//  Created by Jayvin Tiya Silo on 22/08/26.
//
import Foundation

// MARK: - Shared small attribute wrappers
// BGG's XML represents most values as attributes, e.g. <yearpublished value="1995"/>

nonisolated struct BGGValueAttr: Codable, Hashable {
    let value: String
}

nonisolated struct BGGNameAttr: Codable, Hashable {
    let type: String?
    let value: String
}


// MARK: - /thing response
nonisolated struct BGGThingResponse: Codable {
    let items: [BGGItem]

    enum CodingKeys: String, CodingKey {
        case items = "item"
    }
}

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

// MARK: - /xmlapi/geeklist/{id} response
// Note: this is the older v1 XML API, not xmlapi2 — its root element is
// <geeklist>, with each entry as a direct <item> child carrying attributes
// (rather than the id/value-attribute style used elsewhere).

nonisolated struct BGGGeeklistResponse: Codable {
    let title: String?
    let items: [BGGGeeklistItem]

    enum CodingKeys: String, CodingKey {
        case title
        case items = "item"
    }
}

nonisolated struct BGGGeeklistItem: Codable, Identifiable, Hashable {
    /// The geeklist entry's own id (unique within the list).
    let id: String
    /// The id of the underlying game/thing — this is what /thing?id= expects.
    let objectId: String
    let objectName: String
    let objectType: String?
    let subtype: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case objectId = "objectid"
        case objectName = "objectname"
        case objectType = "objecttype"
        case subtype
        case username
    }

    var displaySubtype: String {
        switch subtype {
        case "boardgameexpansion": return "Expansion"
        case "boardgameaccessory": return "Accessory"
        case "boardgame": return "Board Game"
        default: return subtype?.capitalized ?? ""
        }
    }
}
