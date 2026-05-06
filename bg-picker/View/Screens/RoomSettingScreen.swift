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

struct SettingsPickerRow<T: Hashable & RawRepresentable & CaseIterable>: View
where T.RawValue == String {

    let label: String
    @Binding var selection: T

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Menu {
                Picker(label, selection: $selection) {
                    ForEach(Array(T.allCases), id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selection.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.18))
        )
    }
}
#Preview {
    RoomSettingScreen()
}
