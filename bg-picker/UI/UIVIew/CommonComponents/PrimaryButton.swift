import SwiftUI

struct PrimaryButton: View {
    enum Style: Equatable {
        case filled
        case outlined
    }

    @Environment(\.isEnabled) private var isEnabled

    let title: String
    var style: Style = .filled
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(background)
                .overlay {
                    if style == .outlined {
                        Capsule()
                            .stroke(Color("PrimaryButton"), lineWidth: 2)
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            Color("PrimaryButton")
        case .outlined:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        style == .filled ? .black.opacity(0.82) : .white
    }
}

struct NextPrimaryButton: View {
    let action: () -> Void

    var body: some View {
        PrimaryButton(title: "Next", action: action)
    }
}

struct ReadyPrimaryButton: View {
    let action: () -> Void

    var body: some View {
        PrimaryButton(title: "Ready", action: action)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Create Room", action: {})
        PrimaryButton(title: "Join Room", style: .outlined, action: {})
    }
    .padding()
    .background(Color.purple)
}
