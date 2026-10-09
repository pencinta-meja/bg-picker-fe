import SwiftUI

struct PodiumCard: View {
    let group: RoomResultGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.title)
                .font(.title2.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.cards) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            artwork(for: card)
                                .frame(width: 109, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(card.title)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .frame(width: 109, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func artwork(for card: BoardGameCard) -> some View {
        if let local = card.thumbnailLocalImage {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
        } else if let url = card.thumbnailURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    placeholder
                } else {
                    ProgressView().tint(.white)
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.08)
            Image(systemName: "photo")
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
