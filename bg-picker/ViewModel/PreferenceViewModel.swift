//
//  PreferenceViewModel.swift
//  bg-picker
//

import SwiftUI
import Combine
import SwiftData

class PreferenceViewModel: ObservableObject {

    private let games: [BoardGame]

    init(games: [BoardGame]) {
        self.games = games
    }

    func getAllMechanics(completion: @escaping ([Mechanic]) -> ()) {
        completion(Mechanic.allCases)
    }

    func selectedMechanics(selectedMechanics: Set<Mechanic>, completion: @escaping (Bool) -> ()) {
        // Convert the user's saved BoardGame collection → BoardgameDto for the swipe engine
        let dtos: [BoardgameDto] = games.map { game in
            BoardgameDto(
                id: game.persistentModelID.hashValue.description,
                name: game.name,
                cover_image_path: game.thumbnailPath ?? "",
                gameplay_image_path: game.gameplayImagePath ?? "",
                description: game.desc,
                complexity: game.complexity,
                minPlayers: game.minPlayers,
                maxPlayers: game.maxPlayers,
                minDuration: game.minPlayingTime,
                maxDuration: game.maxPlayingTime
            )
        }

        SwipeManager.shared.saveSwipeList(dtos)
        completion(true)
    }
}
