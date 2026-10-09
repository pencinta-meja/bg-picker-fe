import Foundation

nonisolated enum RoomGamePhase: String, Codable, Equatable {
    case idle
    case waitingForPlayers
    case synchronizing
    case waitingForReady
    case readyToStart
    case started
    case lockedOut
    case failed
}

nonisolated struct RoomParticipant: Codable, Identifiable, Equatable {
    let id: String
    var displayName: String
    var isConnected: Bool
    var isReady: Bool
}

nonisolated enum RoomSwipeDecision: String, Codable, Equatable {
    case rejected
    case accepted
}

nonisolated struct RoomSwipeProgress: Codable, Equatable {
    var revision: Int = 0
    var decisions: [String: RoomSwipeDecision] = [:]
    var isFinished: Bool = false

    var acceptedGameIDs: Set<String> {
        Set(decisions.compactMap { $0.value == .accepted ? $0.key : nil })
    }
}

struct RoomResultGroup: Identifiable, Equatable {
    let voteCount: Int
    let finishedPlayerCount: Int
    let cards: [BoardGameCard]

    var id: String { "\(voteCount)-of-\(finishedPlayerCount)" }
    var title: String { "\(voteCount)/\(finishedPlayerCount) Matches" }
}

nonisolated struct RoomWireParticipant: Codable, Equatable {
    let id: String
    let displayName: String
    let isConnected: Bool
    let isReady: Bool
}

nonisolated struct RoomWirePreference: Codable, Equatable {
    let playerID: String
    let revision: Int
    let categories: [String]
    let isReady: Bool
}

nonisolated struct RoomWireProgress: Codable, Equatable {
    let playerID: String
    let progress: RoomSwipeProgress
}

nonisolated struct RoomWireSnapshot: Codable {
    let sessionID: UUID
    let authorityID: String
    let revision: Int
    let phase: RoomGamePhase
    let participants: [RoomWireParticipant]
    let preferences: [RoomWirePreference]
    let progress: [RoomWireProgress]
    let frozenPlayerIDs: [String]
    let canonicalGameIDs: [String]
    let sourceChecksum: String?
}

nonisolated enum RoomWireKind: String, Codable {
    case hello
    case snapshot
    case sourceManifest
    case sourceChunk
    case sourceReady
    case preference
    case start
    case progress
    case locked
    case stateRequest
}

nonisolated struct RoomWireEnvelope: Codable, Identifiable {
    static let currentVersion = 1

    let version: Int
    let id: UUID
    let sessionID: UUID?
    let revision: Int
    let kind: RoomWireKind
    let payload: Data

    init<Value: Encodable>(
        sessionID: UUID?,
        revision: Int,
        kind: RoomWireKind,
        value: Value
    ) throws {
        version = Self.currentVersion
        id = UUID()
        self.sessionID = sessionID
        self.revision = revision
        self.kind = kind
        payload = try JSONEncoder().encode(value)
    }

    func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        try JSONDecoder().decode(type, from: payload)
    }
}

nonisolated struct RoomHelloPayload: Codable {
    let playerID: String
    let displayName: String
}

nonisolated struct RoomSourceManifest: Codable {
    let transferID: UUID
    let byteCount: Int
    let chunkCount: Int
    let checksum: String
}

nonisolated struct RoomSourceChunk: Codable {
    let transferID: UUID
    let index: Int
    let data: Data
}

nonisolated struct RoomSourceReady: Codable {
    let checksum: String
}

nonisolated struct RoomLockedPayload: Codable {
    let message: String
}
