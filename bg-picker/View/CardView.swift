//
//  CardView.swift
//  bg-picker
//
//  Created by Filipus Darren Siswanto on 05/05/26.
//
import SwiftUI

struct CardView: View {
    enum SwipeDirection {
        case left, right, none
    }

    struct Model: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let description: String
        let imageURL: URL?
        var swipeDirection: SwipeDirection = .none
    }

    var model: Model
    var cardWidth: CGFloat
    var cardHeight: CGFloat
    var dragOffset: CGSize
    var isTopCard: Bool
    var isSecondCard: Bool
    @State private var showsDetailSheet = false

    var body: some View {
        let imageHeight = cardHeight * 0.68

        cardBody(width: cardWidth, height: cardHeight, imageHeight: imageHeight)
            .frame(width: cardWidth, height: cardHeight)
            .offset(y: stackOffset)
            .rotationEffect(.degrees(stackRotation))
            .scaleEffect(stackScale)
            .sheet(isPresented: $showsDetailSheet) {
                detailSheet
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func cardBody(width: CGFloat, height: CGFloat, imageHeight: CGFloat) -> some View {
        if isTopCard {
            mainCard(width: width, height: height, imageHeight: imageHeight)
        } else {
            peekCard(width: width, height: height, imageHeight: imageHeight)
        }
    }

    private func mainCard(width: CGFloat, height: CGFloat, imageHeight: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)

            ZStack(alignment: .bottomLeading) {
                cardImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaledToFit()
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(model.description)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(10)
        }
        .frame(width: width, height: height)
        .shadow(
            color: getShadowColor(),
            radius: 14,
            x: 0,
            y: 6
        )
        .overlay(alignment: .topTrailing) {
            Button {
                showsDetailSheet = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white, Color(red: 0.36, green: 0.10, blue: 0.56))
                    .background(Circle().fill(Color.white))
            }
            .offset(x: 14, y: -14)
        }
    }

    private func peekCard(width: CGFloat, height: CGFloat, imageHeight: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(10)
        }
        .frame(width: width, height: height)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardImage: some View {
        if let imageURL = model.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .accessibilityLabel(model.title)
                case .failure:
                    placeholderCard(systemImage: "photo")
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemGray6))
                        ProgressView()
                            .tint(.gray)
                    }
                @unknown default:
                    placeholderCard(systemImage: "photo")
                }
            }
        } else {
            placeholderCard(systemImage: "photo")
        }
    }

    private var detailSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cardImage
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(model.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text(model.description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var stackOffset: CGFloat {
        if isTopCard {
            return 0
        }

        if isSecondCard {
            return -20
        }

        return -35
    }

    private var stackRotation: Double {
        if isTopCard {
            return 0
        }

        if isSecondCard {
            return -4
        }

        return 6
    }

    private var stackScale: CGFloat {
        if isTopCard {
            return 1
        }

        if isSecondCard {
            return 0.97
        }

        return 0.94
    }

    private func placeholderCard(systemImage: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))

            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.gray)
        }
    }

    private func getShadowColor() -> Color {
        if dragOffset.width > 0 {
            return Color.green.opacity(0.8)
        } else if dragOffset.width < 0 {
            return Color.red.opacity(0.8)
        } else {
            return Color.black.opacity(0.18)
        }
    }
}


#Preview {
    ContentView()
}
