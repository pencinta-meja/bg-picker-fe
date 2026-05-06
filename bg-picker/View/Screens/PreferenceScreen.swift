import SwiftUI

struct PreferenceScreen: View {
    @State private var selectedMechanics: Set<Mechanic> = []

    private let mechanics = Mechanic.allCases

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
                Text("Im looking to play a game that involves..")
                    .foregroundStyle(.white)
                    .font(Font.title)

                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(mechanicRows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 12) {
                            ForEach(mechanicRows[rowIndex]) { mechanic in
                                MechanicButton(
                                    title: mechanic.rawValue
                                ) {
                                    print("hello")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 27)
                .padding(.top, 70)
                
                Spacer()

                NextPrimaryButton {
                    print("HELLO")
                }
                .padding(.horizontal, 27)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 40)
        }
    }
}


#Preview {
    PreferenceScreen()
}
