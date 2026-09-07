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
