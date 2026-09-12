nonisolated struct BGGThingResponse: Codable {
    /// Decoded as optional so a response with no `<item>` children (an id that
    /// matched nothing) yields an empty list instead of failing the whole decode.
    private let item: [BGGItem]?

    var items: [BGGItem] { item ?? [] }

    enum CodingKeys: String, CodingKey {
        case item
    }
}
