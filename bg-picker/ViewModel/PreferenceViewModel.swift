import SwiftUI
import Combine


class PreferenceViewModel: ObservableObject {
    @ObservedObject private var networkManager = NetworkManager.shared

    func getAllMechanics(completion: @escaping ([Mechanic]) -> ()) {
        networkManager.get(endpoint: "http://187.77.115.63/boardgame/room/\(RoomManager.shared.id!)/mechanics") { (response: GetBoardgameMechanicsResponseDto?) in
            DispatchQueue.main.async {
                if let response = response {
                    let mechanics = response.mechanics.compactMap { Mechanic.fromString($0) }
                    completion(mechanics)
                } else {
                    print("Failed to fetch mechanics")
                    completion([])
                }
            }
        }
    }
    
    func selectedMechanics(selectedMechanics: Set<Mechanic>, completion: @escaping (Bool) -> ()) {
        let userId = UserManager.shared.id ?? ""
        let roomId = RoomManager.shared.id ?? ""
        
        let mechanics = selectedMechanics.map { $0.rawValue }
        
        let payload: [String: Any] = ["mechanics": mechanics]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            completion(false)
            return
        }
        
        let endpoint = "http://187.77.115.63/user/\(userId)/room/\(roomId)/mechanics"
        
        networkManager.post(endpoint: endpoint, payload: payloadData) { (response: GenerateSwipeListResponseDto?) in
            if let response = response {
                SwipeManager.shared.saveSwipeList(response.boardgames)
                completion(true)
            } else {
                print("Failed to save mechanics")
                completion(false)
            }
        }
    }
}
