import Foundation

struct ApiConfig {
    static var baseURL = URL(string: "http://127.0.0.1:8000")! // temporary local server
}

struct MerchantResolveResponse: Codable {
    let merchant: String
    let mcc: String?
    let category: String?
}

struct ScoreRequest: Codable {
    let merchant: String
    let mcc: String?
    let category: String?
    let cards: [String]
}

struct ScoreResponse: Codable {
    let top: [CardRec]
}

struct CardRec: Codable {
    let card: String
    let score: Double
    let reason: String
}

class ApiClient {
    
    func resolve(lat: Double, lon: Double) async throws -> MerchantResolveResponse {
        let url = ApiConfig.baseURL.appendingPathComponent("resolve")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add query parameters
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon))
        ]
        request.url = components.url
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ApiError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MerchantResolveResponse.self, from: data)
    }
    
    func score(req: ScoreRequest) async throws -> ScoreResponse {
        let url = ApiConfig.baseURL.appendingPathComponent("score")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(req)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ApiError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ScoreResponse.self, from: data)
    }
}

enum ApiError: Error {
    case invalidResponse
    case decodingError
}
