import SwiftUI
import Combine

class WaitingRoomViewModel: ObservableObject {
    @ObservedObject private var networkManager = NetworkManager.shared
    
    func startRoom(completion: @escaping () -> ()) {
        let isHost = RoomManager.shared.isHost ?? false
        
        if isHost {
            startRoomAsHost(completion: completion)
        } else {
            checkRoomStatus(completion: completion)
        }
    }
    
    private func startRoomAsHost(completion: @escaping () -> ()) {
        print("User is Host: Starting Room")
        
        let payload: [String: Any] = [
            "userId": UserManager.shared.id ?? "",
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            return
        }
        
        networkManager.post(endpoint: "http://187.77.115.63/room/\(RoomManager.shared.id!)/start", payload: payloadData) { (response: StartRoomResponseDto?) in
            DispatchQueue.main.async {
                if let response = response {
                    RoomManager.shared.id = response.room.id
                    RoomManager.shared.code = response.room.code
                    RoomManager.shared.isHost = UserManager.shared.id == response.room.host.id
                    completion()
                } else {
                    print("Failed to start the room")
                }
            }
        }
    }
    
    private func checkRoomStatus(completion: @escaping () -> ()) {
        print("User is not Host: Checking Room Status")
        
        networkManager.get(endpoint: "http://187.77.115.63/room/\(RoomManager.shared.id!)") { (response: GetRoomResponseDto?) in
            DispatchQueue.main.async {
                if let response = response {
                    if response.room.status.rawValue == RoomStatus.swiping.rawValue {
                        print("Room is currently in swiping status")
                    } else {
                        print("Room status is not swiping: \(response.room.status.rawValue)")
                    }
                    completion()
                } else {
                    print("Failed to get room status")
                }
            }
        }
    }
}
