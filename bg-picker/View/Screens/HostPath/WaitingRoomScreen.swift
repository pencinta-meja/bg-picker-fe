//
//  WaitingRoomScreen.swift
//  bg-picker
//
//  Created by Danniel on 07/05/26.
//

import SwiftUI
import Combine

struct WaitingRoomScreen: View {
    var userName: String = UserManager.shared.name
    
    var roomPin: String = RoomManager.shared.code
    var readyCount: Int = 0
    var totalCount: Int = 0
    
    @State private var dotCount = 0
    
    @Binding var path: NavigationPath
    
    @ObservedObject private var viewModel = WaitingRoomViewModel()
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("\(userName)'s Room")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 26)
                    .onReceive(timer) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                
                Spacer()
                
                ReadyPrimaryButton(action: {
                    viewModel.startRoom {
                        path.append(Route.mechanicPreference)
                    }
                })
                    .padding(.bottom, 88)
                    .padding(.horizontal, 52)
            }
            VStack(spacing: 0) {
                Spacer()
                
                Text("Waiting\(String(repeating: ".", count: dotCount))")
                    .font(.body)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(roomPin)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
//                Text("\(readyCount) / \(totalCount) Ready")
//                    .font(.title3)
//                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                Spacer()
            }

        }
    }
}

#Preview {
    WaitingRoomScreen(path: .constant(NavigationPath()))
}
