import SwiftUI
import Combine

class PodiumViewModel: ObservableObject {
    @Published var roomResults: [RoomResultDto] = []
    
    init() {
        if let results = RoomManager.shared.roomResult {
            self.roomResults = results
            print("Loaded from cache")
            print(RoomManager.shared.roomResult!)
        }
    }

    func categorizeResults() -> [String: [RoomResultDto]] {
        var categorizedResults: [String: [RoomResultDto]] = [:]
        
        categorizedResults["All Matches"] = roomResults
        
        categorizedResults["5/6 Matches"] = roomResults.filter { $0.numLikes >= 5 }
        categorizedResults["4/6 Matches"] = roomResults.filter { $0.numLikes == 4 }
        categorizedResults["3/6 Matches"] = roomResults.filter { $0.numLikes == 3 }
        
        return categorizedResults
    }
    
    // Function to group results by numLikes
    func groupResultsByLikes() -> [Int: [RoomResultDto]] {
        var groupedResults: [Int: [RoomResultDto]] = [:]
        
        // Group by numLikes
        for result in roomResults {
            let numLikes = result.numLikes
            if groupedResults[numLikes] == nil {
                groupedResults[numLikes] = []
            }
            groupedResults[numLikes]?.append(result)
        }
        
        return groupedResults
    }
}
