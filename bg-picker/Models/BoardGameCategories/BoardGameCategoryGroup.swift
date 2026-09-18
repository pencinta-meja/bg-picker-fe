// xcode: set sdk=iOS

//
//  BoardGameCategoryGroup.swift
//  bg-picker
//
//  Created by Danniel on 17/09/26.
//
//  Folds the 84 BGG categories into 13 pickable groups.
//

nonisolated enum BoardGameCategoryGroup: String, Identifiable, CaseIterable {
    case wargameMilitary = "Wargame & Military History"
    case historicalSetting = "Historical Setting"
    case fantasyAndSciFi = "Fantasy & Sci-Fi"
    case adventureExploration = "Adventure & Exploration"
    case strategyAbstract = "Abstract & Strategy"
    case socialDeduction = "Social Deduction & Negotiation"
    case economyIndustry = "Economy & Industry"
    case cardsDiceWords = "Cards, Dice & Words"
    case partyAndPopCulture = "Party & Pop Culture"
    case sportsAndAction = "Sports & Action"
    case natureScienceLife = "Nature, Science & Life"
    case collectibleAndDigital = "Collectible & Digital"
    case expansions = "Expansions"

    var id: String { rawValue }

    static func fromString(_ string: String) -> BoardGameCategoryGroup? {
        return BoardGameCategoryGroup(rawValue: string)
    }
}

nonisolated extension BoardGameCategory {
    /// The group this category is pickable under.
    ///
    /// Optional rather than force-unwrapped: all 84 categories are mapped today, so
    /// this is never nil in practice. The optional is what makes adding an 85th
    /// category and forgetting to map it drop quietly instead of crashing.
    var group: BoardGameCategoryGroup? { Self.groupByCategory[self] }

    private static let groupByCategory: [BoardGameCategory: BoardGameCategoryGroup] = [
        .abstractStrategy: .strategyAbstract,
        .actionDexterity: .sportsAndAction,
        .adventure: .adventureExploration,
        .ageOfReason: .wargameMilitary,
        .americanCivilWar: .wargameMilitary,
        .americanIndianWars: .wargameMilitary,
        .americanRevolutionaryWar: .wargameMilitary,
        .americanWest: .historicalSetting,
        .ancient: .historicalSetting,
        .animals: .natureScienceLife,
        .arabian: .historicalSetting,
        .aviationFlight: .adventureExploration,
        .bluffing: .socialDeduction,
        .book: .partyAndPopCulture,
        .cardGame: .cardsDiceWords,
        .childrensGame: .partyAndPopCulture,
        .cityBuilding: .economyIndustry,
        .civilWar: .wargameMilitary,
        .civilization: .historicalSetting,
        .collectibleComponents: .collectibleAndDigital,
        .comicBookStrip: .partyAndPopCulture,
        .deduction: .socialDeduction,
        .dice: .cardsDiceWords,
        .economic: .economyIndustry,
        .educational: .natureScienceLife,
        .electronic: .collectibleAndDigital,
        .environmental: .natureScienceLife,
        .expansionForBaseGame: .expansions,
        .exploration: .adventureExploration,
        .fanExpansion: .expansions,
        .fantasy: .fantasyAndSciFi,
        .farming: .economyIndustry,
        .fighting: .sportsAndAction,
        .gameSystem: .strategyAbstract,
        .horror: .fantasyAndSciFi,
        .humor: .partyAndPopCulture,
        .industryManufacturing: .economyIndustry,
        .koreanWar: .wargameMilitary,
        .mafia: .socialDeduction,
        .math: .natureScienceLife,
        .matureAdult: .natureScienceLife,
        .maze: .strategyAbstract,
        .medical: .natureScienceLife,
        .medieval: .historicalSetting,
        .memory: .cardsDiceWords,
        .miniatures: .collectibleAndDigital,
        .modernWarfare: .wargameMilitary,
        .moviesTVRadioTheme: .partyAndPopCulture,
        .murderMystery: .socialDeduction,
        .music: .partyAndPopCulture,
        .mythology: .fantasyAndSciFi,
        .napoleonic: .wargameMilitary,
        .nautical: .adventureExploration,
        .negotiation: .socialDeduction,
        .novelBased: .partyAndPopCulture,
        .number: .cardsDiceWords,
        .partyGame: .partyAndPopCulture,
        .pikeAndShot: .wargameMilitary,
        .pirates: .adventureExploration,
        .political: .socialDeduction,
        .postNapoleonic: .wargameMilitary,
        .prehistoric: .historicalSetting,
        .printAndPlay: .collectibleAndDigital,
        .puzzle: .strategyAbstract,
        .racing: .sportsAndAction,
        .realTime: .sportsAndAction,
        .religious: .natureScienceLife,
        .renaissance: .historicalSetting,
        .scienceFiction: .fantasyAndSciFi,
        .spaceExploration: .fantasyAndSciFi,
        .spiesSecretAgents: .socialDeduction,
        .sports: .sportsAndAction,
        .territoryBuilding: .economyIndustry,
        .trains: .economyIndustry,
        .transportation: .economyIndustry,
        .travel: .adventureExploration,
        .trivia: .cardsDiceWords,
        .videoGameTheme: .partyAndPopCulture,
        .vietnamWar: .wargameMilitary,
        .wargame: .wargameMilitary,
        .wordGame: .cardsDiceWords,
        .worldWarI: .wargameMilitary,
        .worldWarII: .wargameMilitary,
        .zombies: .fantasyAndSciFi,
    ]
}
