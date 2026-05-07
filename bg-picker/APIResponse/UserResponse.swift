struct CreateUserResponseDto: Decodable {
    let user: UserDto
}

struct UserDto: Decodable {
    let id: String
    let name: String
}
