//
//  PreferenceScreen.swift
//  bg-picker
//

import SwiftUI

struct PreferenceScreen: View {
    @State private var selectedMechanics: Set<Mechanic> = []
    @Binding var path: NavigationPath
    @State private var mechanics: [Mechanic] = []

    // Pull the user's game collection from environment
    @Environment(CollectionViewModel.self) private var collectionViewModel

    // ViewModel is created after we have the games
    @State private var viewModel: PreferenceViewModel? = nil

    private var mechanicRows: [[Mechanic]] {
        stride(from: 0, to: mechanics.count, by: 2).map { index in
            Array(mechanics[index..<min(index + 2, mechanics.count)])
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(alignment: .center) {
                Text("Create Room")
                    .foregroundStyle(.white)
                    .font(Font.title)
                    .padding(.bottom, 100)
                Text("I'm looking to play a game that involves..")
                    .foregroundStyle(.white)
                    .font(Font.title)

                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(mechanicRows.indices, id: \.self) { rowIndex in
                            HStack(spacing: 12) {
                                ForEach(mechanicRows[rowIndex]) { mechanic in
                                    MechanicButton(title: mechanic.rawValue) {
                                        if selectedMechanics.contains(mechanic) {
                                            selectedMechanics.remove(mechanic)
                                        } else {
                                            selectedMechanics.insert(mechanic)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 27)
                    .padding(.top, 70)
                }

                Spacer()

                NextPrimaryButton {
                    viewModel?.selectedMechanics(selectedMechanics: selectedMechanics) { success in
                        if success {
                            if UserManager.shared.id == nil {
                                UserManager.shared.saveId(id: "dummy-user-id")
                            }
                            if RoomManager.shared.id == nil {
                                RoomManager.shared.saveId(id: "dummy-room-id")
                                RoomManager.shared.saveIsHost(isHost: true)
                            }
                            path.append(Route.swiping)
                        } else {
                            print("Failed to save mechanics")
                        }
                    }
                }
                .padding(.horizontal, 27)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 40)
        }
        .onAppear {
            // Build the ViewModel with the current collection games
            viewModel = PreferenceViewModel(games: collectionViewModel.games)
            viewModel?.getAllMechanics { fetchedMechanics in
                mechanics = fetchedMechanics
            }
        }
    }
}

#Preview {
    PreferenceScreen(path: .constant(NavigationPath()))
}
