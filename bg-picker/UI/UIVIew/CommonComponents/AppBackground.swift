import SwiftUI

struct AppBackground<Content: View>: View {
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            content()
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    AppBackground {
        Text("Board Game Picker")
    }
}
