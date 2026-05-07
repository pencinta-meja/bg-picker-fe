import Foundation

struct CreateRoomResponseDto: Decodable {
    let room: RoomDto
}

struct RoomDto: Decodable {
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
