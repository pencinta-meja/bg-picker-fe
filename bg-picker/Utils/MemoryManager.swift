//
//  MemoryManager.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import Foundation

final class UserInfo {
    
    static let shared = UserInfo()
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let name = "user_name"
        static let id = "user_id"
        static let isNameSet = "is_name_set"
    }

    var name: String {
        get { defaults.string(forKey: Keys.name) ?? "Anonymous" }
        set { defaults.set(newValue, forKey: Keys.name) }
    }
    
    var id: String? {
        get { defaults.string(forKey: Keys.id) ?? nil }
        set { defaults.set(newValue, forKey: Keys.id) }
    }
    
    func saveName(name: String) {
        self.name = name
    }
    
    func saveId (id: String) {
        self.id = id
    }
    
    func clearSession() {
        self.name = "Anonymous"
        self.id = nil
    }
    
    func isIdSet() -> Bool {
        return self.id != nil
    }
}
