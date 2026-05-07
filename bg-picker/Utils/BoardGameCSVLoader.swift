////
////  BoardGameCSVLoader.swift
////  bg-picker
////
//
//import Foundation
//
//enum BoardGameCSVLoader {
//    private static let nameIndex = 0
//    private static let descriptionIndex = 1
//    private static let complexityIndex = 2
//    private static let bggRatingIndex = 3
//    private static let categoriesIndex = 4
//    private static let thumbnailIndex = 5
//    private static let gameplayIndex = 6
//    private static let minPlayersIndex = 7
//    private static let maxPlayersIndex = 8
//    private static let minPlayTimeIndex = 9
//    private static let maxPlayTimeIndex = 10
//
//    static func loadCards() -> [BoardGameCard] {
//        guard
//            let csvURL = Bundle.main.url(forResource: "listboardgameacad", withExtension: "csv"),
//            let csvText = try? String(contentsOf: csvURL, encoding: .utf8)
//        else {
//            return []
//        }
//
//        return csvText
//            .components(separatedBy: .newlines)
//            .dropFirst()
//            .compactMap { line in
//                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
////                guard !trimmedLine.isEmpty else { return nil }
//
//                let columns = parseCSVLine(trimmedLine)
////                guard columns.count > maxPlayTimeIndex else { return nil }
//
//                let title = columns[nameIndex]
//                let description = columns[descriptionIndex]
//                let categories = columns[categoriesIndex]
//                let thumbnailPath = columns[thumbnailIndex]
//                let gameplayPath = columns[gameplayIndex]
//                let complexity = columns[complexityIndex].replacingOccurrences(of: ",", with: ".")
//                let bggRating = columns[bggRatingIndex].replacingOccurrences(of: ",", with: ".")
//                let minPlayers = columns[minPlayersIndex]
//                let maxPlayers = columns[maxPlayersIndex]
//                let minPlayTime = columns[minPlayTimeIndex]
//                let maxPlayTime = columns[maxPlayTimeIndex]
//
//                return BoardGameCard(
//                    title: title,
//                    description: description,
//                    thumbnailURL: URL(string: thumbnailPath),
//                    gameplayImageURL: URL(string: gameplayPath),
//                    categoriesText: categories,
//                    playTimeText: minPlayTime == maxPlayTime ? "\(minPlayTime) min" : "\(minPlayTime)-\(maxPlayTime) min",
//                    playersText: minPlayers == maxPlayers ? "\(minPlayers) players" : "\(minPlayers)-\(maxPlayers) players",
//                    complexityText: complexity,
//                    ratingText: "\(bggRating)/10"
//                )
//            }
//    }
//
//    private static func parseCSVLine(_ line: String) -> [String] {
//        var values: [String] = []
//        var currentValue = ""
//        var isInsideQuotes = false
//
//        for character in line {
//            switch character {
//            case "\"":
//                isInsideQuotes.toggle()
//            case "," where !isInsideQuotes:
//                values.append(currentValue)
//                currentValue = ""
//            default:
//                currentValue.append(character)
//            }
//        }
//
//        values.append(currentValue)
//        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//    }
//}
