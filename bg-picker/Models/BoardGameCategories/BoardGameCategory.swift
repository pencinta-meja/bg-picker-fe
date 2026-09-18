//
//  BoardGameCategory.swift
//  bg-picker
//
//  The values BGG returns as `<link type="boardgamecategory">` — what a game is *about*
//  (Fantasy, Wargame, Economic).
//
//  Not to be confused with `boardgamemechanic`, which is how a game is *played*
//  (Hand Management, Worker Placement). BGG sends both; this app reads only categories.
//
//  There are 84 of these, which is far too many to show as a preference grid, so
//  `BoardGameCategoryGroup` folds them into 13.
//

nonisolated enum BoardGameCategory: String, Identifiable, CaseIterable {
    case abstractStrategy = "Abstract Strategy"
    case actionDexterity = "Action / Dexterity"
    case adventure = "Adventure"
    case ageOfReason = "Age of Reason"
    case americanCivilWar = "American Civil War"
    case americanIndianWars = "American Indian Wars"
    case americanRevolutionaryWar = "American Revolutionary War"
    case americanWest = "American West"
    case ancient = "Ancient"
    case animals = "Animals"
    case arabian = "Arabian"
    case aviationFlight = "Aviation / Flight"
    case bluffing = "Bluffing"
    case book = "Book"
    case cardGame = "Card Game"
    case childrensGame = "Children's Game"
    case cityBuilding = "City Building"
    case civilWar = "Civil War"
    case civilization = "Civilization"
    case collectibleComponents = "Collectible Components"
    case comicBookStrip = "Comic Book / Strip"
    case deduction = "Deduction"
    case dice = "Dice"
    case economic = "Economic"
    case educational = "Educational"
    case electronic = "Electronic"
    case environmental = "Environmental"
    case expansionForBaseGame = "Expansion for Base-game"
    case exploration = "Exploration"
    case fanExpansion = "Fan Expansion"
    case fantasy = "Fantasy"
    case farming = "Farming"
    case fighting = "Fighting"
    case gameSystem = "Game System"
    case horror = "Horror"
    case humor = "Humor"
    case industryManufacturing = "Industry / Manufacturing"
    case koreanWar = "Korean War"
    case mafia = "Mafia"
    case math = "Math"
    case matureAdult = "Mature / Adult"
    case maze = "Maze"
    case medical = "Medical"
    case medieval = "Medieval"
    case memory = "Memory"
    case miniatures = "Miniatures"
    case modernWarfare = "Modern Warfare"
    case moviesTVRadioTheme = "Movies / TV / Radio theme"
    case murderMystery = "Murder/Mystery"
    case music = "Music"
    case mythology = "Mythology"
    case napoleonic = "Napoleonic"
    case nautical = "Nautical"
    case negotiation = "Negotiation"
    case novelBased = "Novel-based"
    case number = "Number"
    case partyGame = "Party Game"
    case pikeAndShot = "Pike and Shot"
    case pirates = "Pirates"
    case political = "Political"
    case postNapoleonic = "Post-Napoleonic"
    case prehistoric = "Prehistoric"
    case printAndPlay = "Print & Play"
    case puzzle = "Puzzle"
    case racing = "Racing"
    case realTime = "Real-time"
    case religious = "Religious"
    case renaissance = "Renaissance"
    case scienceFiction = "Science Fiction"
    case spaceExploration = "Space Exploration"
    case spiesSecretAgents = "Spies/Secret Agents"
    case sports = "Sports"
    case territoryBuilding = "Territory Building"
    case trains = "Trains"
    case transportation = "Transportation"
    case travel = "Travel"
    case trivia = "Trivia"
    case videoGameTheme = "Video Game Theme"
    case vietnamWar = "Vietnam War"
    case wargame = "Wargame"
    case wordGame = "Word Game"
    case worldWarI = "World War I"
    case worldWarII = "World War II"
    case zombies = "Zombies"

    var id: String { rawValue }

    static func fromString(_ string: String) -> BoardGameCategory? {
        return BoardGameCategory(rawValue: string)
    }
}
