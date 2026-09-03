import Foundation

nonisolated enum SecretVariables {
    static var apiKey : String {
        guard let key = Bundle.main.infoDictionary?["BGG_API_KEY"] as? String else {
            fatalError("Missing BGG API Key")
        }
        
        return key
    }
}
