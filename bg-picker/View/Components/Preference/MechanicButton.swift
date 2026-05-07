import SwiftUI

struct MechanicButton: View {
    let title: String
    let action: () -> Void
    @State private var isClicked = false
    
    private let purpleColor = Color(
        red: 88.0 / 255.0,
        green: 26.0 / 255.0,
        blue: 130.0 / 255.0
    )
    var body: some View {
        Button(action: {
          isClicked.toggle()
          action()
        }) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isClicked ? purpleColor : .white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Circle()
                    .fill(isClicked ? purpleColor : .white)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: isClicked ? "xmark" : "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isClicked ? .white : purpleColor)
                    }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .frame(height: 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isClicked ? .white : .clear)
        )
        .glassEffect(
            isClicked ? .regular.interactive() : .regular,
            in: RoundedRectangle(cornerRadius: 10)
        )

            
    }
}
