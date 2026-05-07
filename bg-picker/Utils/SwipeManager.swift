import Foundation

final class SwipeManager {
    
    static let shared = SwipeManager()
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let swipeList = "swipe_list"
    }
    
    func saveSwipeList(_ swipeList: [BoardgameDto]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(swipeList) {
            defaults.set(encoded, forKey: Keys.swipeList)
        }
    }
    
    func getSwipeList() -> [BoardgameDto]? {
        if let savedSwipeList = defaults.data(forKey: Keys.swipeList) {
            let decoder = JSONDecoder()
            if let loadedSwipeList = try? decoder.decode([BoardgameDto].self, from: savedSwipeList) {
                return loadedSwipeList
            }
        }
        return nil
    }
    
    func clearSwipeList() {
        defaults.removeObject(forKey: Keys.swipeList)
    }
}
