import SwiftUI
import Combine

class PinInputViewModel: ObservableObject {
    @ObservedObject private var networkManager = NetworkManager.shared
    
    var pin: String = ""
    
    func joinRoom(pin: String, completion: @escaping () -> ()) {
        guard !pin.isEmpty else {
            print("PIN cannot be empty")
            return
        }

        let payload: [String: Any] = [
            "userId": UserManager.shared.id ?? "",
            "roomCode": pin,
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            return
        }
        
        networkManager.post(endpoint: "http://187.77.115.63/room/join", payload: payloadData) { (response: JoinRoomResponseDto?) in
            DispatchQueue.main.async {
                if let response = response {
                    RoomManager.shared.id = response.room.id
                    RoomManager.shared.code = response.room.code
                    RoomManager.shared.isHost = UserManager.shared.id == response.room.host.id
                    completion()
                } else {
                    print("Failed to join the room")
                }
            }
        }
    }
}
