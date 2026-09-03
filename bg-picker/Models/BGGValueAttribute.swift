nonisolated struct BGGValueAttr: Codable, Hashable {
    let value: String
}

nonisolated struct BGGNameAttr: Codable, Hashable {
    let type: String?
    let value: String
}
