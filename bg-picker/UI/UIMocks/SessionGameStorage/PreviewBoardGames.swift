//
//  PreviewBoardGames.swift
//  bg-picker
//
//  DEBUG-only `BGGItem` fixtures for Xcode previews.
//
//  Fixtures are `BGGItem`, not `BoardGameCard`, on purpose. Everything a card displays is
//  then produced by the real `BoardGameCard.init(item:)`, so a preview exercises the
//  actual formatting instead of hand-written display strings — and `games` and `cards`
//  cannot drift apart the way two independent fixture lists would.
//
//  The values are real: pulled once from `/xmlapi2/thing?id=…&stats=1` for these ids, so
//  a contributor can cross-check any of them against boardgamegeek.com. They are a
//  preview fixture, not a catalog: nothing outside `#if DEBUG` may reference them, and
//  nothing here is a substitute for a real geeklist fetch.
//

#if DEBUG
import Foundation

enum PreviewBoardGames {
    /// A deck large enough to see the card stack's offsets and swipe all the way to the
    /// end without it taking a minute.
    static let all: [BGGItem] = [catan, azul, wingspan, pandemic, codenames, gloomhaven, brassBirmingham]

    // MARK: - Entries

    /// Carries BGG's real double-encoding (`&#10;`, `&amp;`) so `cleanDescription` is
    /// exercised rather than assumed — a preview should show line breaks, not `&#10;`.
    static let catan = item(
        id: "13",
        name: "Catan",
        description: "Picture the excitement of discovering and settling a new island."
            + "&#10;&#10;Players guide expeditions of settlers, trading brick, lumber, wool, grain "
            + "&amp; ore to build roads and cities across the island of Catan.",
        year: "1995",
        minPlayers: 3,
        maxPlayers: 4,
        minPlayTime: 60,
        maxPlayTime: 120,
        playingTime: 120,
        categories: [.economic, .negotiation],
        rating: "7.09024",
        weight: "2.2804",
        usersRated: "144547",
        thumbnail: "https://cf.geekdo-images.com/0XODRpReiZBFUffEcqT5-Q__small/img/SNVfF23OQafv3u8xdFolJnMkBoM=/fit-in/200x150/filters:strip_icc()/pic9156909.png",
        image: "https://cf.geekdo-images.com/0XODRpReiZBFUffEcqT5-Q__original/img/oRc0AomWA9ZtFqQDZiZbIyKE1j0=/0x0/filters:format(png)/pic9156909.png"
    )

    static let azul = item(
        id: "230802",
        name: "Azul",
        description: "Introduced by the Moors, azulejos were originally white and blue ceramic tiles. "
            + "Players draft tiles from shared factory displays and lay them to decorate the walls "
            + "of the Royal Palace of Evora — wasted tiles cost points.",
        year: "2017",
        minPlayers: 2,
        maxPlayers: 4,
        minPlayTime: 30,
        maxPlayTime: 45,
        playingTime: 45,
        categories: [.abstractStrategy, .renaissance],
        rating: "7.7113",
        weight: "1.7733",
        usersRated: "111072",
        thumbnail: "https://cf.geekdo-images.com/aPSHJO0d0XOpQR5X-wJonw__small/img/ccsXKrdGJw-YSClWwzVUwk5Nh9Y=/fit-in/200x150/filters:strip_icc()/pic6973671.png",
        image: "https://cf.geekdo-images.com/aPSHJO0d0XOpQR5X-wJonw__original/img/AkbtYVc6xXJF3c9EUrakklcclKw=/0x0/filters:format(png)/pic6973671.png"
    )

    /// The one solo-capable entry, so the preview covers `playersText`'s "1–5 players".
    static let wingspan = item(
        id: "266192",
        name: "Wingspan",
        description: "You are bird enthusiasts seeking to discover and attract the best birds to "
            + "your network of wildlife preserves. Each bird extends a chain of powerful "
            + "combinations in one of your habitats.",
        year: "2019",
        minPlayers: 1,
        maxPlayers: 5,
        minPlayTime: 40,
        maxPlayTime: 70,
        playingTime: 70,
        categories: [.animals, .cardGame, .educational, .environmental],
        rating: "7.9937",
        weight: "2.48",
        usersRated: "115662",
        thumbnail: "https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__small/img/VNToqgS2-pOGU6MuvIkMPKn_y-s=/fit-in/200x150/filters:strip_icc()/pic4458123.jpg",
        image: "https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__original/img/cI782Zis9cT66j2MjSHKJGnFPNw=/0x0/filters:format(jpeg)/pic4458123.jpg"
    )

    /// `minPlayTime == maxPlayTime`, so `playTimeText` renders its single-value "45 min"
    /// branch rather than a range.
    static let pandemic = item(
        id: "30549",
        name: "Pandemic",
        description: "Four diseases have broken out and it is up to a team of specialists to find "
            + "cures before humanity is lost. Players win or lose together.",
        year: "2008",
        minPlayers: 2,
        maxPlayers: 4,
        minPlayTime: 45,
        maxPlayTime: 45,
        playingTime: 45,
        categories: [.medical, .travel],
        rating: "7.51035",
        weight: "2.3934",
        usersRated: "142832",
        thumbnail: "https://cf.geekdo-images.com/S3ybV1LAp-8SnHIXLLjVqA__small/img/oqViRj6nVxK3m36NluTxU1PZkrk=/fit-in/200x150/filters:strip_icc()/pic1534148.jpg",
        image: "https://cf.geekdo-images.com/S3ybV1LAp-8SnHIXLLjVqA__original/img/IsrvRLpUV1TEyZsO5rC-btXaPz0=/0x0/filters:format(jpeg)/pic1534148.jpg"
    )

    /// Five categories, so `categoriesText`'s `prefix(3)` truncation is visible — and one
    /// of them, "Spies / Secret Agents", is a real BGG value `BoardGameCategory` has no
    /// case for. It shows in the card subtitle (raw `categoryNames`) and drops out of
    /// `categories`, which is exactly what production does with a category the enum has
    /// not caught up with.
    static let codenames = item(
        id: "178900",
        name: "Codenames",
        description: "Two rival spymasters know the secret identities of 25 agents. Their teammates "
            + "know the agents only by their codenames, and a one-word clue can point to "
            + "several words on the table.",
        year: "2015",
        minPlayers: 2,
        maxPlayers: 8,
        minPlayTime: 15,
        maxPlayTime: 15,
        playingTime: 15,
        categories: [.cardGame, .deduction, .partyGame, .wordGame],
        unknownCategories: ["Spies / Secret Agents"],
        rating: "7.52295",
        weight: "1.2523",
        usersRated: "97241",
        thumbnail: "https://cf.geekdo-images.com/nC6ifPCDnAItwoKSKXVrnw__small/img/1iZav_8ZqurrDbvkZA9GcFhB5x0=/fit-in/200x150/filters:strip_icc()/pic8907965.jpg",
        image: "https://cf.geekdo-images.com/nC6ifPCDnAItwoKSKXVrnw__original/img/Id-jjIer_61ZbvI2_RVRCeBZFY4=/0x0/filters:format(jpeg)/pic8907965.jpg"
    )

    /// Carries `boardgamemechanic` links alongside its categories, so a preview proves the
    /// card subtitle filters on `type` and never shows a mechanic as a category.
    static let gloomhaven = item(
        id: "174430",
        name: "Gloomhaven",
        description: "A game of Euro-inspired tactical combat in a persistent world of shifting "
            + "motives. Players take on the role of wandering adventurers whose choices "
            + "permanently alter the campaign.",
        year: "2017",
        minPlayers: 1,
        maxPlayers: 4,
        minPlayTime: 60,
        maxPlayTime: 120,
        playingTime: 120,
        categories: [.adventure, .exploration, .fantasy, .fighting, .miniatures],
        mechanics: ["Cooperative Game", "Hand Management", "Legacy Game"],
        rating: "8.53165",
        weight: "3.92",
        usersRated: "67776",
        thumbnail: "https://cf.geekdo-images.com/sZYp_3BTDGjh2unaZfZmuA__small/img/veqFeP4d_3zNhFc3GNBkV95rBEQ=/fit-in/200x150/filters:strip_icc()/pic2437871.jpg",
        image: "https://cf.geekdo-images.com/sZYp_3BTDGjh2unaZfZmuA__original/img/7d-lj5Gd1e8PFnD97LYFah2c45M=/0x0/filters:format(jpeg)/pic2437871.jpg"
    )

    static let brassBirmingham = item(
        id: "224517",
        name: "Brass: Birmingham",
        description: "An economic strategy game telling the story of competing entrepreneurs in "
            + "Birmingham during the industrial revolution. Build, network and exploit "
            + "demand across the canal and rail eras.",
        year: "2018",
        minPlayers: 2,
        maxPlayers: 4,
        minPlayTime: 60,
        maxPlayTime: 120,
        playingTime: 120,
        categories: [.ageOfReason, .economic, .industryManufacturing, .postNapoleonic, .trains, .transportation],
        rating: "8.55928",
        weight: "3.8609",
        usersRated: "60322",
        thumbnail: "https://cf.geekdo-images.com/x3zxjr-Vw5iU4yDPg70Jgw__small/img/o18rjEemoWaVru9Y2TyPwuIaRfE=/fit-in/200x150/filters:strip_icc()/pic3490053.jpg",
        image: "https://cf.geekdo-images.com/x3zxjr-Vw5iU4yDPg70Jgw__original/img/FpyxH41Y6_ROoePAilPNEhXnzO8=/0x0/filters:format(jpeg)/pic3490053.jpg"
    )

    // MARK: - Builder

    /// Keeps each entry readable. `BGGItem`'s memberwise init takes thirteen arguments of
    /// XML wrapper types, which buries the values that actually matter to a preview.
    ///
    /// `categories` is typed as `BoardGameCategory`, so a mistyped category is a compile
    /// error instead of a silently dropped link. `unknownCategories` is the escape hatch
    /// for a real BGG value the enum has no case for.
    private static func item(
        id: String,
        name: String,
        description: String,
        year: String,
        minPlayers: Int,
        maxPlayers: Int,
        minPlayTime: Int,
        maxPlayTime: Int,
        playingTime: Int,
        categories: [BoardGameCategory],
        unknownCategories: [String] = [],
        mechanics: [String] = [],
        rating: String,
        weight: String,
        usersRated: String,
        thumbnail: String,
        image: String
    ) -> BGGItem {
        let categoryLinks = (categories.map(\.rawValue) + unknownCategories).map {
            BGGLinkAttr(type: "boardgamecategory", id: nil, value: $0)
        }
        let mechanicLinks = mechanics.map {
            BGGLinkAttr(type: "boardgamemechanic", id: nil, value: $0)
        }

        return BGGItem(
            id: id,
            names: [BGGNameAttr(type: "primary", value: name)],
            description: description,
            yearPublished: BGGValueAttr(value: year),
            minPlayers: BGGValueAttr(value: String(minPlayers)),
            maxPlayers: BGGValueAttr(value: String(maxPlayers)),
            playingTime: BGGValueAttr(value: String(playingTime)),
            minPlayTime: BGGValueAttr(value: String(minPlayTime)),
            maxPlayTime: BGGValueAttr(value: String(maxPlayTime)),
            image: image,
            thumbnail: thumbnail,
            links: categoryLinks + mechanicLinks,
            statistics: BGGStatistics(
                ratings: BGGRatings(
                    average: BGGValueAttr(value: rating),
                    averageWeight: BGGValueAttr(value: weight),
                    usersRated: BGGValueAttr(value: usersRated)
                )
            )
        )
    }
}
#endif
