//
//  SetNameScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct SetNameScreen: View {
    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack (spacing: 100) {
                Spacer()
                Text("Who is this?")
                    .foregroundStyle(.white).font(Font.title)
                HStack(alignment: .center, spacing: 4) {
                    TextField("Plain", text: .constant("Halo"))
                        .font(
                            .headline
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 106.5)
                        .padding(.vertical, 14)
                }
                .glassEffect(.clear, in: .rect(cornerRadius: 10))   
                .padding(.horizontal, 52)
                .padding(.vertical, 6)
                
                Spacer()
                NextButton(action: {
                    print("Halo")
                })
                .padding(
                    .bottom, 88
                ).padding(
                    .horizontal, 52
                )
            }
        }
        
    }
}

struct NextButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Next")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("PrimaryButton"))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    SetNameScreen()
}
    
