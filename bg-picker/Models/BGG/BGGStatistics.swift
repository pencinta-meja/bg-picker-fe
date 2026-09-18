// MARK: - /thing?stats=1 statistics block
// Only returned when the request carries `stats=1`. This is the only place BGG
// exposes complexity (`averageweight`, a 1-5 scale) and the community rating
// (`average`, a 1-10 scale).

nonisolated struct BGGStatistics: Codable, Hashable {
    let ratings: BGGRatings?
}

nonisolated struct BGGRatings: Codable, Hashable {
    let average: BGGValueAttr?
    let averageWeight: BGGValueAttr?
    let usersRated: BGGValueAttr?

    enum CodingKeys: String, CodingKey {
        case average
        case averageWeight = "averageweight"
        case usersRated = "usersrated"
    }
}
