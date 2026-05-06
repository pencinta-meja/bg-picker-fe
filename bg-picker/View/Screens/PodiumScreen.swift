//
//  PodiumScreen.swift
//  bg-picker
//
//  Created by Jayvin Tiya Silo on 06/05/26.
//

import SwiftUI
import Combine

struct PodiumScreen: View {
    
    var body: some View {
        ZStack (){
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            
            
            VStack(){
                HStack{
                    Text("Abraar's Room")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(.top)
                }
                ScrollView{
                    PodiumCard(title: "All Matches", images: ["background","background","background","background","background"])
                    PodiumCard(title: "5/6 Matches", images: ["background","background","background"])
                    PodiumCard(title: "4/6 Matches", images: ["background","background"])
                    PodiumCard(title: "3/6 Matches", images: ["background","background"])
                }
                
            }
            
            
        }
    }
}
#Preview {
    PodiumScreen()
}
