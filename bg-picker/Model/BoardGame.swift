import Foundation
import SwiftData

enum Genre: String, CaseIterable, Codable {
    // Resource & Trading
    case resourceManagement = "Resource Management"
    case trading = "Trading"
    case commoditySpeculation = "Commodity Speculation"
    case auction = "Auction"
    
    // Dice & Luck
    case diceRolling = "Dice Rolling"
    case pushYourLuck = "Push Your Luck"
    
    // Card Play
    case cardDrafting = "Card Drafting"
    case handManagement = "Hand Management"
    case setCollection = "Set Collection"
    case trickTaking = "Trick-taking"
    case cardPlay = "Card Play"
    
    // Cooperative & Deduction
    case cooperative = "Cooperative"
    case deduction = "Deduction"
    case memory = "Memory"
    case puzzleSolving = "Puzzle Solving"
    
    // Social & Bluffing
    case bluffing = "Bluffing"
    case partnership = "Partnership"
    case playerElimination = "Player Elimination"
    case takeThat = "Take That"
    
    // Strategy & Building
    case abstractStrategy = "Abstract Strategy"
    case routeBuilding = "Route Building"
    case networkBuilding = "Network Building"
    case actionQueue = "Action Queue"
    case gridMovement = "Grid Movement"
    
    // Party & Casual
    case patternRecognition = "Pattern Recognition"
    case patternBuilding = "Pattern Building"
    case dexterity = "Dexterity"
    case realTime = "Real-time"
    
    // Word
    case wordBuilding = "Word Building"
    case betting = "Betting"
}

@Model
final class BoardGame {
    var name: String
    var oneLiner: String
    var desc: String
    
    var complexity: Float
    var rating: Float
    
    var genres: [Genre]
    
    var thumbnailPath: String?
    var gameplayImagePath: String?
    
    var minPlayers: Int
    var maxPlayers: Int
    
    var minPlayingTime: Int
    var maxPlayingTime: Int
    
    init(
        name: String,
        oneLiner: String = "",
        desc: String = "",
        complexity: Float = 0.0,
        rating: Float = 0.0,
        genres: [Genre] = [],
        thumbnailPath: String? = nil,
        gameplayImagePath: String? = nil,
        minPlayers: Int = 1,
        maxPlayers: Int = 1,
        minPlayingTime: Int = 0,
        maxPlayingTime: Int = 0
    ) {
        self.name = name
        self.oneLiner = oneLiner
        self.desc = desc
        self.complexity = complexity
        self.rating = rating
        self.genres = genres
        self.thumbnailPath = thumbnailPath
        self.gameplayImagePath = gameplayImagePath
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.minPlayingTime = minPlayingTime
        self.maxPlayingTime = maxPlayingTime
    }
}
