import Foundation

struct GetRoomResponseDto: Decodable {
    let room: RoomDto
}

struct CreateRoomResponseDto: Decodable {
    let room: RoomDto
}

struct RoomDto: Decodable, Encodable {
    let id: String
    let host: UserDto
    let code: String
    let numPlayer: Int
    let maxDuration: Int
    let status: RoomStatus
    let resultBoardgameIds: [String]
}

struct JoinRoomResponseDto: Decodable {
    let room: RoomDto
}

struct StartRoomResponseDto: Decodable {
    let room: RoomDto
}

struct RoomResultDto: Decodable, Encodable {
    let id: String
    let room: RoomDto
    let boardgame: BoardgameDto
    let numLikes: Int
    let initials: String
}

struct FinishRoomResponseDto: Decodable {
    let roomResults: [RoomResultDto]
}
