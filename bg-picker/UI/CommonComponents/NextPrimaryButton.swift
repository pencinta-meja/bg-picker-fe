//
//  PrimaryButton.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//
import SwiftUI

struct NextPrimaryButton: View {
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

struct ReadyPrimaryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Ready")
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
