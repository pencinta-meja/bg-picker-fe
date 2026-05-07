struct GetBoardgameMechanicsResponseDto: Decodable {
    let mechanics: [String]
}

struct BoardgameDto: Decodable, Encodable {
    let id: String
    let name: String
    let cover_image_path: String
    let gameplay_image_path: String
    let description: String
    let complexity: Float
    let minPlayers: Int
    let maxPlayers: Int
    let minDuration: Int
    let maxDuration: Int
}

struct GenerateSwipeListResponseDto: Decodable {
    let boardgames: [BoardgameDto]
}

