import SwiftUI

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let purpleColor = Color(
        red: 88.0 / 255.0,
        green: 26.0 / 255.0,
        blue: 130.0 / 255.0
    )
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? purpleColor : .white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                
                Circle()
                    .fill(isSelected ? purpleColor : .white)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: isSelected ? "xmark" : "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isSelected ? .white : purpleColor)
                    }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? .white : .clear)
        )
        .glassEffect(
            isSelected ? .regular.interactive() : .regular,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
