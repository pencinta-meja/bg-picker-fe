import SwiftUI
import Combine

final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isSuccess = false
    
    private var cancellable: AnyCancellable? = nil
    
    func post<T: Decodable>(endpoint: String, payload: Data, completion: @escaping (T?) -> Void) {
        isLoading = true
        error = nil
        isSuccess = false
        
        guard let url = URL(string: endpoint) else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.error = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue: { response in
                self.isSuccess = true
                completion(response)
            })
    }
    
    func get<T: Decodable>(endpoint: String, completion: @escaping (T?) -> Void) {
        isLoading = true
        error = nil
        isSuccess = false
        
        guard let url = URL(string: endpoint) else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.error = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue: { response in
                self.isSuccess = true
                completion(response)
            })
    }
}
