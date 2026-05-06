//
//  LoadingScreen.swift
//  bg-picker
//
//  Created by Jayvin Tiya Silo on 05/05/26.
//

import SwiftUI
import Combine

struct LoadingScreen: View {
    @State private var dotCount = 0
    @State private var rotationAngle: Double = 0
    @State private var rotatingRight = true
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack (alignment: .top){
            VStack(alignment: .center, spacing: 112){
                
                Text("Abraar's Room")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(.top)
        
                Text("Waiting for others\(String(repeating: ".", count: dotCount))")
                    .font(.body)
                    .foregroundStyle(.white)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(width: 109, height: 169)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .rotationEffect(.degrees(rotationAngle), anchor: .bottom)
                    .animation(.easeInOut(duration: 0.5), value: rotationAngle)
            }
            .padding(.top, 70)
            .frame(width: .infinity, height: .infinity
                   , alignment: .bottom)
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4

            if rotatingRight {
                rotationAngle += 6
                if rotationAngle >= 6 { rotatingRight = false }
            } else {
                rotationAngle -= 6
                if rotationAngle <= -6 { rotatingRight = true }
            }
        }
    }
}
#Preview {
    LoadingScreen()
}
