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
        
        var validName: Bool {
            !(name.trimmingCharacters(in: .whitespacesAndNewlines) == "")
        }
        
        func saveName(completion: () -> ()){
            if !validName {
                shouldShake.toggle()
                HapticManager.shared.error()
                return
            }
            
            UserManager.shared.name = name
            UserManager.shared.isNameSet = true
            
            completion()
        }
}

