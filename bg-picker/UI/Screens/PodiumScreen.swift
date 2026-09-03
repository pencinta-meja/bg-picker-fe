import SwiftUI

struct PodiumScreen: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "trophy")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.45))

                Text("No Results Yet")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Results will appear after a Game Center session is completed.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    PodiumScreen(path: .constant(NavigationPath()))
}
