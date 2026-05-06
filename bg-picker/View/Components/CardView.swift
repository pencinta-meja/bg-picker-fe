//
//  CardView.swift
//  bg-picker
//
//  Created by Filipus Darren Siswanto on 05/05/26.
//
import SwiftUI

struct CardView: View {
    var model: BoardGameCard
    
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
                    .frame(width: width - 20, height: height - 20)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.title)
                        .font(.custom("Impact", size: 30))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(model.description)
                        .font(.system(size: 15, weight: .regular))
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
        remoteImage(url: model.thumbnailURL)
    }

    private var detailSheet: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    remoteImage(url: model.gameplayImageURL ?? model.thumbnailURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.4)
                        .overlay(alignment: .bottom) {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color(red: 22/255, green: 5/255, blue: 36/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: geometry.size.height * 0.16)
                        }
                        .clipped()

                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .top, spacing: 16) {
                            remoteImage(url: model.thumbnailURL)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(model.title)
                                    .font(.custom("Impact", size: 30))
                                    .foregroundStyle(.white)

                                Text(model.categoriesText)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
                            GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16)
                        ], spacing: 16) {
                            statCard(icon: "clock", label: "Play Time", value: model.playTimeText)
                            statCard(icon: "person.2", label: "Players", value: model.playersText)
                            statCard(icon: "dial.medium", label: "Complexity", value: model.complexityText)
                            statCard(icon: "star", label: "BGG Rating", value: model.ratingText)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("About")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)

                            Text(model.description)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: geometry.size.width, alignment: .topLeading)
            }
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(red: 22/255, green: 5/255, blue: 36/255))
    }

    @ViewBuilder
    private func remoteImage(url: URL?) -> some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel(model.title)
                case .failure:
                    placeholderCard(systemImage: "photo")
                case .empty:
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                        ProgressView()
                            .tint(.white.opacity(0.8))
                    }
                @unknown default:
                    placeholderCard(systemImage: "photo")
                }
            }
        } else {
            placeholderCard(systemImage: "photo")
        }
    }

    private func statCard(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
