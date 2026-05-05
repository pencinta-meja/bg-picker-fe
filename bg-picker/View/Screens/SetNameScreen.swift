//
//  SetNameScreen.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import SwiftUI

struct SetNameScreen: View {
    @State var name: String = ""
    
    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 100) {
                    Text("Who is this?")
                        .foregroundStyle(.white)
                        .font(Font.title)
                    
                    HStack(alignment: .center, spacing: 4) {
                        TextField("Plain", text: $name)
                            .font(.headline)
                            .tint(.white)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 14)
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 20 {
                                    name = String(newValue.prefix(20))
                                }
                            }
                    }
                    .glassEffect(.clear, in: .rect(cornerRadius: 10))
                    .padding(.horizontal, 52)
                    .padding(.vertical, 6)
                }
                
                Spacer()
                
                PrimaryButton(action: {})
                    .padding(.bottom, 88)
                    .padding(.horizontal, 52)
            }
        }.ignoresSafeArea(.container)
    }
}

#Preview {
    SetNameScreen()
}
    
