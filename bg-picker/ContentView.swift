//
//  ContentView.swift
//  bg-picker
//
//  Created by Danniel on 02/05/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Font") {
                for family: String in UIFont.familyNames {
                    print(family)
                    for names: String in UIFont.fontNames(forFamilyName: family) {
                        print("== \(names)")
                    }
                }
            }
//            Text(key + " " + url)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
