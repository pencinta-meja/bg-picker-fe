import Foundation

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
