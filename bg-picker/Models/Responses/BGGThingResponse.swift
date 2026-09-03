nonisolated struct BGGThingResponse: Codable {
    let items: [BGGItem]

    enum CodingKeys: String, CodingKey {
        case items = "item"
    }
}
