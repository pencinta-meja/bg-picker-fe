//
//  RoomSettingScreen.swift
//  bg-picker
//
//  Created by Danniel on 07/05/26.
//

import SwiftUI

enum GroupSize: String, CaseIterable {
    case two    = "2 Players"
    case three  = "3 Players"
    case four   = "4 Players"
    case sixPlus = "6+ Players"
}

enum MaxDuration: String, CaseIterable {
    case fifteen    = "15 Minutes"
    case thirty     = "30 Minutes"
    case fortyFive  = "45 Minutes"
    case sixty      = "60 Minutes"
}

struct RoomSettingScreen: View {
    
    @State private var groupSize: GroupSize = .two
    @State private var maxDuration: MaxDuration = .fifteen
    @ObservedObject private var viewModel = RoomSettingViewModel()
    
    @Binding var path: NavigationPath
    
    var userName : String = UserManager.shared.name
    
    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack (spacing: 0) {
                Text("\(userName) Room")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 26)
                
                Spacer()                
                NextPrimaryButton(action: {
                    viewModel.createRoom(groupSize: groupSize, maxDuration: maxDuration) {
                        path.append(Route.waitingRoom)
                    }
                })
                .padding(.vertical, 88)
                .padding(.horizontal, 52)
            }
            
            VStack(spacing: 12) {
                Spacer()
                
                SettingsPickerRow(label: "Group Size", selection: $groupSize)
                SettingsPickerRow(label: "Max Duration", selection: $maxDuration)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    RoomSettingScreen(path: .constant(NavigationPath()))
}
