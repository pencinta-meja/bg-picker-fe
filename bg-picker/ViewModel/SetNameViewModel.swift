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
        
        func saveName(completion: @escaping () -> ()){
            if !validName {
                shouldShake.toggle()
                HapticManager.shared.error()
                return
            }
            
            let payload: [String: String] = ["name": name]
            
            guard let payload = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                self.networkManager.error = "Failed to serialize data"
                return
            }
            
            networkManager.post(endpoint: "http://187.77.115.63/user", payload: payload) { (response: CreateUserResponseDto?) in
                DispatchQueue.main.async {
                    if let response = response {
                        UserManager.shared.saveName(name: response.user.name)
                        UserManager.shared.saveId(id: response.user.id)
                        UserManager.shared.isNameSet = true
                        completion()
                    } else {
                        self.networkManager.error = "Failed to save name"
                    }
                }
            }
        }
}

