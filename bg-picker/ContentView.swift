//
//  ContentView.swift
//  bg-picker
//
//  Created by Danniel on 02/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var swipeModel: SwipeableCardsView.Model

    init() {
        _swipeModel = StateObject(
            wrappedValue: SwipeableCardsView.Model(cards: BoardGameCSVLoader.loadCards())
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Abra's Room")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 70)

                Spacer(minLength: 8)

                SwipeableCardsView(model: swipeModel) { _ in
                    finishSwiping()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: 560)
                .onAppear {
                    swipeModel.reset()
                }

                Spacer(minLength: 32)

                Button(action: finishSwiping) {
                    Text("Finish")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(red: 0.93, green: 0.88, blue: 0.99))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
    }

    private func finishSwiping() {
        print(swipeModel.swipedCards.map(\.title))
        swipeModel.reset()
    }
}

#Preview {
    ContentView()
}

private enum BoardGameCSVLoader {
    private static let nameIndex = 0
    private static let descriptionIndex = 1
    private static let thumbnailIndex = 4
    private static let gameplayIndex = 5

    static func loadCards() -> [CardView.Model] {
        guard
            let csvURL = Bundle.main.url(forResource: "listboardgameacad", withExtension: "csv"),
            let csvText = try? String(contentsOf: csvURL, encoding: .utf8)
        else {
            return []
        }

        return csvText
            .components(separatedBy: .newlines)
            .dropFirst()
            .compactMap { line in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLine.isEmpty else { return nil }

                let columns = parseCSVLine(trimmedLine)
                guard columns.count > gameplayIndex else { return nil }

                let title = columns[nameIndex]
                let description = columns[descriptionIndex]
                let preferredImagePath = columns[thumbnailIndex].isEmpty ? columns[gameplayIndex] : columns[thumbnailIndex]

                return CardView.Model(
                    title: title,
                    description: description,
                    imageURL: URL(string: preferredImagePath)
                )
            }
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var isInsideQuotes = false

        for character in line {
            switch character {
            case "\"":
                isInsideQuotes.toggle()
            case "," where !isInsideQuotes:
                values.append(currentValue)
                currentValue = ""
            default:
                currentValue.append(character)
            }
        }

        values.append(currentValue)
        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

