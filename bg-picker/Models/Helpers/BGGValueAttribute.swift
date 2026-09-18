nonisolated struct BGGValueAttr: Codable, Hashable {
    let value: String
}

nonisolated struct BGGNameAttr: Codable, Hashable {
    let type: String?
    let value: String
}

/// A `<link>` element on a /thing item. One item carries many of these — categories,
/// mechanics, designers, publishers — all distinguished only by `type`.
nonisolated struct BGGLinkAttr: Codable, Hashable {
    let type: String?
    let id: String?
    let value: String
}
