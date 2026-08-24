import SwiftUI
import Combine

class WaitingRoomViewModel: ObservableObject {
    
    func startRoom(completion: @escaping () -> ()) {
        // Skipping network call for now
        completion()
    }
}
