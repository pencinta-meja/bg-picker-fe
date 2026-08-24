import SwiftUI
import Combine

class RoomSettingViewModel: ObservableObject {
    
    func createRoom(groupSize: GroupSize, maxDuration: MaxDuration, completion: @escaping () -> ()) {
        // Skipping network call for now
        RoomManager.shared.saveCode(code: "TEST123")
        RoomManager.shared.saveId(id: "dummy-room-id")  // ← add this
        RoomManager.shared.saveIsHost(isHost: true)
        completion()
    }
}
