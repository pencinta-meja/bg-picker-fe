//
//  LobbyScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct LobbyScreen: View {
    var userName : String = UserManager.shared.name
    
    var body: some View {
        NavigationStack {
            VStack (spacing: 106) {
                Spacer()
                Text(
                    "Hello \(userName)"
                ).font(.largeTitle).foregroundStyle(.white)
                VStack (spacing: 12){
                    Button(action: {
                        
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.app.fill")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text("Create Room")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("PrimaryButton"))
                        .clipShape(Capsule())
                    }
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.to.line")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("Join Room")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color("PrimaryButton"), lineWidth: 4)
                        )
                    }
                }.padding(.horizontal, 51)
                Spacer()
            }
            .background() {
                Image("BackgroundImage")
                    .resizable()
                    .ignoresSafeArea()
            }
        
        }
    }
}

#Preview {
    LobbyScreen()
}

