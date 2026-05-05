//
//  StarterScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct StarterScreen: View {
    private let isFirstLaunch = UserManager.shared.isNameSet
    
    var body: some View {
        if isFirstLaunch {
            SetNameScreen()
        } else {
            
        }
    }
}
