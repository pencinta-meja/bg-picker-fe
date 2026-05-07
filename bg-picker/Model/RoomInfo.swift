import Foundation
//
//  RoomInfo.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

struct RoomInfo {
    var roomName: String
    var roomCode: String
}

enum RoomStatus: String, CaseIterable, Decodable, Encodable {
    case waiting = "Waiting"
    case swiping = "Swiping"
    case finished = "Finished"
}
