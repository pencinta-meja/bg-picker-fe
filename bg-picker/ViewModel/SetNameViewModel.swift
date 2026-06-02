//
//  SetNameViewModel.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI
import Combine

class SetNameViewModel: ObservableObject{
        
        @Published var name: String = ""
        @Published var shouldShake = false
    
        @ObservedObject private var networkManager = NetworkManager.shared
        
        var validName: Bool {
            !(name.trimmingCharacters(in: .whitespacesAndNewlines) == "")
        }
        
    func saveName(completion: @escaping () -> ()) {
        if !validName {
            shouldShake.toggle()
            HapticManager.shared.error()
            return
        }
        
        // Skipping network call for now
        UserManager.shared.saveName(name: name)
        UserManager.shared.saveId(id: "dummy-user-id")  // ← add this
        UserManager.shared.isNameSet = true
        completion()
    }
}
