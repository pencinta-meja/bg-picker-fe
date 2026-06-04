

import SwiftUI
import SwiftData

@Observable
final class CollectionViewModel {
    var games: [BoardGame] = []
    var isEmpty: Bool { games.isEmpty }
    var gameCount: Int { games.count }

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadGames()
    }

    private func loadGames() {
        let descriptor = FetchDescriptor<BoardGame>()
        
        do {
            games = try modelContext.fetch(descriptor)
        }
        catch {
            // showing some logic
            print(error)
        }
        
        if games.isEmpty {
            seedDefaultGames()
        }
    }

    private func seedDefaultGames() {
        defaultGames().forEach { game in
            modelContext.insert(game)
            games.append(game)
        }
        save()
    }


    func addGame(_ game: BoardGame) {
        modelContext.insert(game)
        games.append(game)
        save()
    }

    func removeGame(_ game: BoardGame) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        
        modelContext.delete(game)
        games.remove(at: index)
        save()
    }

    func removeGames(at offsets: IndexSet) {
        let toDelete = offsets.map { games[$0] }
        toDelete.forEach { game in
            modelContext.delete(game)
        }
        games.remove(atOffsets: offsets)
        save()
    }
    private func save() {
        try? modelContext.save()
    }

    // Default game library
    private func defaultGames() -> [BoardGame] {
        [
            BoardGame(
                name: "Unlock!",
                oneLiner: "Escape the room with cards.",
                desc: "Cooperative card game with an escape room theme.",
                complexity: 4.2, rating: 7.2,
                genres: [.cooperative, .puzzleSolving, .realTime],
                thumbnailPath: "https://cf.geekdo-images.com/biw1DYvUdQ4-ZgIOtUDqhQ__itemrep@2x/img/9avN4pJI0lzZ5fkTaxBBhZ9aX4s=/fit-in/492x600/filters:strip_icc()/pic4432319.jpg",
                gameplayImagePath: "https://cf.geekdo-images.com/wO3R1utC_anu5xaMm17pZw__imagepage@2x/img/SKXo9qFZrX3v-u2BvaVtGqEOZ74=/fit-in/1800x1200/filters:strip_icc()/pic5070494.jpg",
                minPlayers: 1, maxPlayers: 6, minPlayingTime: 60, maxPlayingTime: 60
            ),
            BoardGame(
                name: "Cat Between Us",
                oneLiner: "A casual card game with cats.",
                desc: "Casual card game with a cat theme.",
                complexity: 2.0, rating: 7.1,
                genres: [.cardDrafting, .setCollection],
                thumbnailPath: "https://cf.geekdo-images.com/x9ReeH79kyuLLMu_weSezQ__itemrep@2x/img/_bWXqENa2sDq2_2MpxdioVPCJSQ=/fit-in/492x600/filters:strip_icc()/pic8746816.png",
                gameplayImagePath: "https://cf.geekdo-images.com/pZUL7DutfXeAaFx9PyYFgA__imagepage@2x/img/k2KJvqT6ECOhDSI_dr6dmwlImiI=/fit-in/1800x1200/filters:strip_icc()/pic8884330.jpg",
                minPlayers: 2, maxPlayers: 6, minPlayingTime: 15, maxPlayingTime: 40
            ),
            BoardGame(
                name: "Remi",
                oneLiner: "Arrange suits and match numbers.",
                desc: "Classic card game arranging cards by suits or matching numbers.",
                complexity: 3.6, rating: 5.8,
                genres: [.setCollection, .handManagement],
                thumbnailPath: "https://cf.geekdo-images.com/QhsvR9GY0LbTpj27fairWA__itemrep/img/IIsS7i2vl6oxHijl8GrGzIc7SHM=/fit-in/246x300/filters:strip_icc()/pic186610.jpg",
                gameplayImagePath: "https://image.astronauts.cloud/product-images/2024/12/111191IGradeKartuRemi727Black_fdd9cc74-16e0-4ae0-86f9-25bea5e1b876_900x900.png",
                minPlayers: 2, maxPlayers: 6, minPlayingTime: 30, maxPlayingTime: 60
            ),
          
            BoardGame(
                name: "Sekata",
                oneLiner: "Build and guess Indonesian words.",
                desc: "Indonesian card game for building and guessing words.",
                complexity: 2.0, rating: 6.6,
                genres: [.wordBuilding, .handManagement],
                thumbnailPath: "https://cf.geekdo-images.com/5ktsXOgbcMAkWpG0fc1TaQ__itemrep@2x/img/EzmSHtS2Qz4IZ9RtaRnU4gyQV4k=/fit-in/492x600/filters:strip_icc()/pic9067853.jpg",
                gameplayImagePath: "https://tokoboardgame.com/wp-content/uploads/2025/07/2e09d0f4-c4d4-4860-8cc1-068591d4534e.jpgtplv-aphluv4xwc-origin-jpeg.jpeg",
                minPlayers: 3, maxPlayers: 10, minPlayingTime: 5, maxPlayingTime: 15
            ),
        ]
    }
}
