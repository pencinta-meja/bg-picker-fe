struct CreateUserResponseDto: Decodable {
    let user: UserDto
}

struct UserDto: Decodable, Encodable {
    let id: String
    let name: String
}
