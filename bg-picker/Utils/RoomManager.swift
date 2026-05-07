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
    
    func saveCode(code: String) {
        self.code = code
    }
    
    func saveId (id: String) {
        self.id = id
    }
    
    func saveIsHost (isHost: Bool) {
        self.isHost = isHost
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
