//
//  MemoryManager.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import Foundation
import Combine

final class UserManager: ObservableObject {
    
    static let shared = UserManager()
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
    
    @Published var isNameSet: Bool = UserDefaults.standard.bool(forKey: "is_name_set") {
        didSet { defaults.set(isNameSet, forKey: Keys.isNameSet) }
    }
    
    func saveName(name: String) { self.name = name }
    func saveId(id: String) { self.id = id }
    func clearSession() {
        self.name = "Anonymous"
        self.id = nil
    }
    func isIdSet() -> Bool { return self.id != nil }
}
