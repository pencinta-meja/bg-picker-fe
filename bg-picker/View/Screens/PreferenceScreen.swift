import SwiftUI

struct PreferenceScreen: View {
    @State private var selectedMechanics: Set<Mechanic> = []
    @Binding var path: NavigationPath
    @ObservedObject private var viewModel = PreferenceViewModel()
    @State private var mechanics: [Mechanic] = []

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
                                    }                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 27)
                    .padding(.top, 70)
                }
                
                Spacer()

                NextPrimaryButton {
                    viewModel.selectedMechanics(selectedMechanics: selectedMechanics) { success in
                        if success {
                            print("Mechanics saved successfully")
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
            viewModel.getAllMechanics() { fetchedMechanics in
                mechanics = fetchedMechanics
            }
        }
    }
}

#Preview {
    PreferenceScreen(path: .constant(NavigationPath()))
}
