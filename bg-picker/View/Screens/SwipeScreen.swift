//
//  ContentView.swift
//  bg-picker
//
//  Created by Danniel on 02/05/26.
//

import SwiftUI

struct SwipeScreen: View {
    @Binding var path: NavigationPath
    @ObservedObject private var viewModel = SwipeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("\(UserManager.shared.name)'s Room")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 70)

                Spacer(minLength: 8)

                SwipeableCardsView(swipeableViewModel: viewModel) { _ in
                    finishSwiping()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: 560)
                .onAppear {
                    viewModel.reset()
                }

                Spacer(minLength: 32)

                Button(action: finishSwiping) {
                    Text("Finish")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(red: 0.93, green: 0.88, blue: 0.99))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
    }

    private func finishSwiping() {
        viewModel.finishRoom {
            path.append(Route.podium)
        }
    }
}

//#Preview {
//    SwipeScreen(path: .constant(NavigationPath()))
//}
//
