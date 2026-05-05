//
//  BoardGame.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

struct BoardGame : Codable {
    var name: String
    var description: String
    
    var complexity: Float
    var rating: Float
    
    var categories: [String]
    
    var thumbnailPath: String?
    var gameplayImagePath: String?
    
    var minPlayers: Int
    var maxPlayers: Int
    
    var minPlayingTime: Int // In minutes
    var maxPlayingTime: Int // In minutes
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        
        case complexity
        case rating
        
        case categories
        
        case thumbnailPath = "thumbnail_path"
        case gameplayImagePath = "gameplay_image_path"
        
        case minPlayers = "min_players"
        case maxPlayers = "max_players"
        
        case minPlayingTime = "min_playing_time"
        case maxPlayingTime = "max_playing_time"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? "Unknown"
        
        complexity = try c.decodeIfPresent(Float.self, forKey: .complexity) ?? 0.0
        rating = try c.decodeIfPresent(Float.self, forKey: .rating) ?? 0.0
        
        categories = try c.decodeIfPresent([String].self, forKey: .categories) ?? []
        
        thumbnailPath = try c.decodeIfPresent(String.self, forKey: .thumbnailPath) ?? nil
        gameplayImagePath = try c.decodeIfPresent(String.self, forKey: .gameplayImagePath) ?? nil
        
        minPlayers = try c.decodeIfPresent(Int.self, forKey: .minPlayers) ?? 1
        maxPlayers = try c.decodeIfPresent(Int.self, forKey: .maxPlayers) ?? 1
        
        minPlayingTime = try c.decodeIfPresent(Int.self, forKey: .minPlayingTime) ?? 0
        maxPlayingTime = try c.decodeIfPresent(Int.self, forKey: .maxPlayingTime) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(description, forKey: .description)
        
        try c.encode(complexity, forKey: .complexity)
        try c.encode(rating, forKey: .rating)
        
        try c.encode(categories, forKey: .categories)
        
        try c.encode(thumbnailPath, forKey: .thumbnailPath)
        try c.encode(gameplayImagePath, forKey: .gameplayImagePath)
        
        try c.encode(minPlayers, forKey: .minPlayers)
        try c.encode(maxPlayers, forKey: .maxPlayers)
        
        try c.encode(minPlayingTime, forKey: .minPlayingTime)
        try c.encode(maxPlayingTime, forKey: .maxPlayingTime)
    }
}
