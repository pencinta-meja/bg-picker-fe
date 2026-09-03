enum Mechanic: String, Identifiable, CaseIterable {
    case routeBuilding = "Route Building"
    case abstractStrategy = "Abstract Strategy"
    case cooperative = "Cooperative"
    case gridMovement = "Grid Movement"
    case actionQueue = "Action Queue"
    case partnership = "Partnership"
    case networkBuilding = "Network Building"
    case takeThat = "Take That"
    case realTime = "Real-time"
    case betting = "Betting"
    case resourceManagement = "Resource Management"
    case patternBuilding = "Pattern Building"
    case handManagement = "Hand Management"
    case setCollection = "Set Collection"
    case puzzleSolving = "Puzzle Solving"
    case diceRolling = "Dice Rolling"
    case bluffing = "Bluffing"
    case patternRecognition = "Pattern Recognition"
    case cardDrafting = "Card Drafting"
    case wordBuilding = "Word Building"
    case deduction = "Deduction"
    case trickTaking = "Trick-taking"
    case pushYourLuck = "Push Your Luck"
    case trading = "Trading"
    case memory = "Memory"
    case playerElimination = "Player Elimination"
    case dexterity = "Dexterity"

    var id: String { rawValue }
    
    static func fromString(_ string: String) -> Mechanic? {
        return Mechanic(rawValue: string)
    }
}
