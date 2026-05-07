//
//  MemoryManager.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import Foundation

final class RoomManager {
    
    static let shared = RoomManager()
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let code = "room_code"
        static let isHost = "is_host"
        static let id = "code_id"
        static let roomResult = "room_result"
    }

    var code: String {
        get { defaults.string(forKey: Keys.code) ?? "" }
        set { defaults.set(newValue, forKey: Keys.code) }
    }
    
    var id: String? {
        get { defaults.string(forKey: Keys.id) }
        set { defaults.set(newValue, forKey: Keys.id) }
    }
    
    var isHost: Bool? {
        get { defaults.bool(forKey: Keys.isHost) }
        set { defaults.set(newValue, forKey: Keys.isHost) }
    }
    
    var roomResult: [RoomResultDto]? {
        get {
            if let data = defaults.data(forKey: Keys.roomResult) {
                let decoder = JSONDecoder()
                if let result = try? decoder.decode([RoomResultDto].self, from: data) {
                    return result
                }
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(newValue) {
                    defaults.set(encoded, forKey: Keys.roomResult)
                }
            }
        }
    }
    
    func saveCode(code: String) {
        self.code = code
    }
    
    func saveId (id: String) {
        self.id = id
    }
    
    func saveIsHost (isHost: Bool) {
        self.isHost = isHost
    }
    
    func saveRoomResult(result: [RoomResultDto]) {
        self.roomResult = result
    }
    
    func clearSession() {
        self.code = ""
        self.id = nil
        self.isHost = nil
    }
    
    func isIdSet() -> Bool {
        return self.id != nil
    }
}
