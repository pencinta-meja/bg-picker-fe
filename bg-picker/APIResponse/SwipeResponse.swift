struct SwipeBoardgameResponseDto: Decodable {
    let swipe: SwipeDto
}

struct SwipeDto: Decodable {
    let id: String
    let room: RoomDto
    let player: UserDto
    let boardgame: BoardgameDto
    let isLike: Bool
}
