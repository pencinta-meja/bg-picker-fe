enum Mechanic: String, CaseIterable, Identifiable {
    case acting = "Acting"
    case actionDrafting = "Action Drafting"
    case actionQueue = "Action Queue"
    case bluffing = "Bluffing"
    case bribery = "Bribery"
    case cardPlay = "Card Play"
    case closedDrafting = "Closed Drafting"
    case chaining = "Chaining"
    case contracts = "Contracts"
    case commoditySpeculation = "Commodity Speculation"
    case deckConstruction = "Deck Construction"
    case deckbuilding = "Deckbuilding"

    var id: String {
        rawValue
    }
}
