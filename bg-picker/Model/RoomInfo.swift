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

enum RoomStatus: String, CaseIterable, Decodable {
    case waiting = "Waiting"
    case swping = "Swiping"
    case finished = "Finished"
}
