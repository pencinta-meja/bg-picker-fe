//
//  PodiumCard.swift
//  bg-picker
//
//  Created by Jayvin Tiya Silo on 06/05/26.
//


import SwiftUI

struct PodiumCard: View {
    let title: String
    let images: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(images, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 109, height: 169)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(24)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
    

#Preview {
    PodiumCard(title: "All Matches", images: ["background","background","background", "background"])
}
