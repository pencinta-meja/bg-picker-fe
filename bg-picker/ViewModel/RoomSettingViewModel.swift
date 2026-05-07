import SwiftUI
import Combine


class RoomSettingViewModel: ObservableObject {
    @ObservedObject private var networkManager = NetworkManager.shared
    
    func extractNumber(from string: String, length: Int) -> Int? {
        let limitedString = String(string.prefix(length))
        let scanner = Scanner(string: limitedString)
        var number: Int = 0
        
        if scanner.scanInt(&number) {
            return number
        }
        return nil
    }
    func createRoom(groupSize: GroupSize, maxDuration: MaxDuration, completion: @escaping () -> ()){
        let payload: [String: Any] = [
            "userId": UserManager.shared.id ?? "",
            "numPlayer": extractNumber(from: groupSize.rawValue, length: 1) ?? 0,
            "duration": extractNumber(from: maxDuration.rawValue, length: 2) ?? 0
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize data")
            return
        }
        networkManager.post(endpoint: "http://187.77.115.63/room", payload: payloadData) { (response: CreateRoomResponseDto?) in
            DispatchQueue.main.async {
                if let response = response {
                    completion()
                } else {
                    print("Failed to create room or no response")
                }
            }
        }
    }
}
