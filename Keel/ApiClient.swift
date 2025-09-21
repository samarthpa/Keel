import Foundation
import Combine

struct ApiConfig {
    static var baseURL = URL(string: "http://127.0.0.1:8000")! // temporary local server
}

// MARK: - Response Models

struct MerchantResolveResponse: Codable {
    let merchant: String
    let mcc: String
    let category: String
}

struct ScoreResponse: Codable {
    let top: [CardRec]
}

struct CardRec: Codable {
    let card: String
    let score: Double
    let reason: String
    let merchant: String
    let category: String
}

struct ScoreRequest: Codable {
    let merchant: String
    let mcc: String
    let category: String
    let cards: [String]
}

struct MockVisitRequest: Codable {
    let lat: Double
    let lon: Double
    let user_id: String?
    let user_cards: [String]?
    
    init(lat: Double, lon: Double, user_id: String? = nil, user_cards: [String]? = nil) {
        self.lat = lat
        self.lon = lon
        self.user_id = user_id
        self.user_cards = user_cards
    }
}

struct MockVisitResponse: Codable {
    let merchant: String
    let category: String?
    let mcc: String?
    let confidence: Double
    let top_card: String?
    let reason: String?
    let request_id: String
}

struct VisitResponse: Codable {
    let merchant: String
    let mcc: String
    let category: String
}

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
}

struct EmptyResponse: Codable {
    // Empty response for endpoints that don't return data
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let user_id: Int
    let email: String
}

struct MeResponse: Codable {
    let id: Int
    let email: String
    let created_at: String
}

// MARK: - Error Models

struct ApiErrorResponse: Codable {
    let error: ErrorDetail
}

struct ErrorDetail: Codable {
    let code: String
    let message: String
    let retryable: Bool?
}

// MARK: - ApiClient

class ApiClient: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ApiClient()
    
    // MARK: - Published Properties
    
    @Published var lastError: ApiError?
    @Published var currentRequestID: String?
    
    // MARK: - Private Properties
    
    var cancellables = Set<AnyCancellable>()
    private var currentToken: String?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Token Management
    
    /// Set the current authentication token
    func setToken(_ token: String?) {
        currentToken = token
    }
    
    /// Get the current authentication token
    func getToken() -> String? {
        return currentToken
    }
    
    /// Clear the current authentication token
    func clearToken() {
        currentToken = nil
    }
    
    // MARK: - Request ID Generation
    
    /// Generate a unique request ID for debugging
    private func generateRequestID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 1000...9999)
        return "req_\(timestamp)_\(random)"
    }
    
    // MARK: - Generic HTTP Methods
    
    /// Generic GET request
    func get<T: Codable>(endpoint: String, token: String? = nil) -> AnyPublisher<T, ApiError> {
        let requestID = generateRequestID()
        currentRequestID = requestID
        
        let url = ApiConfig.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        
        // Use provided token, current token, or none
        let authToken = token ?? currentToken
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response in
                try self?.handleResponse(data: data, response: response, requestID: requestID) ?? data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { [weak self] error in
                self?.handleError(error, requestID: requestID) ?? .unknownError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Generic POST request with body
    func post<T: Codable, U: Codable>(endpoint: String, body: T, token: String? = nil) -> AnyPublisher<U, ApiError> {
        let requestID = generateRequestID()
        currentRequestID = requestID
        
        let url = ApiConfig.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        
        // Use provided token, current token, or none
        let authToken = token ?? currentToken
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            return Fail(error: .unknownError("Failed to encode request body"))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response in
                try self?.handleResponse(data: data, response: response, requestID: requestID) ?? data
            }
            .decode(type: U.self, decoder: JSONDecoder())
            .mapError { [weak self] error in
                self?.handleError(error, requestID: requestID) ?? .unknownError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Generic POST request without body
    func post<T: Codable>(endpoint: String, token: String? = nil) -> AnyPublisher<T, ApiError> {
        let requestID = generateRequestID()
        currentRequestID = requestID
        
        let url = ApiConfig.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        
        // Use provided token, current token, or none
        let authToken = token ?? currentToken
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response in
                try self?.handleResponse(data: data, response: response, requestID: requestID) ?? data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { [weak self] error in
                self?.handleError(error, requestID: requestID) ?? .unknownError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication Methods
    
    /// Register a new user
    func register(email: String, password: String) -> AnyPublisher<AuthResponse, ApiError> {
        let request = RegisterRequest(email: email, password: password)
        return post(endpoint: "/auth/register", body: request)
    }
    
    /// Login with email and password
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, ApiError> {
        let request = LoginRequest(email: email, password: password)
        return post(endpoint: "/auth/login", body: request)
    }
    
    /// Get current user information
    func me() -> AnyPublisher<MeResponse, ApiError> {
        return get(endpoint: "/auth/me")
    }
    
    /// Logout (revoke token)
    func logout() -> AnyPublisher<EmptyResponse, ApiError> {
        return post(endpoint: "/auth/logout")
    }
    
    func mockVisit(request: MockVisitRequest) -> AnyPublisher<MockVisitResponse, ApiError> {
        return post(endpoint: "/v1/mock/visit", body: request)
    }
    
    // MARK: - Legacy Async Methods (for backward compatibility)
    
    func resolve(lat: Double, lon: Double) async throws -> MerchantResolveResponse {
        let url = ApiConfig.baseURL.appendingPathComponent("v1/merchant/resolve")
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
        let url = ApiConfig.baseURL.appendingPathComponent("v1/score")
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
    
    // MARK: - Private Methods
    
    private func handleResponse(data: Data, response: URLResponse, requestID: String) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response")
        }
        
        // Log request details for debugging
        print("🌐 [\(requestID)] \(httpResponse.url?.absoluteString ?? "unknown") - \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            lastError = .unauthorized
            throw ApiError.unauthorized
        case 400, 409, 422:
            // Try to parse error response from backend
            if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError.backendError(
                    statusCode: httpResponse.statusCode,
                    code: errorResponse.error.code,
                    message: errorResponse.error.message,
                    retryable: errorResponse.error.retryable ?? false
                )
            } else {
                throw ApiError.backendError(
                    statusCode: httpResponse.statusCode,
                    code: "UNKNOWN",
                    message: "Unknown error occurred",
                    retryable: false
                )
            }
        case 500...599:
            throw ApiError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw ApiError.unknownError("Unexpected status code: \(httpResponse.statusCode)")
        }
    }
    
    private func handleError(_ error: Error, requestID: String) -> ApiError {
        if let apiError = error as? ApiError {
            return apiError
        } else if let decodingError = error as? DecodingError {
            return .unknownError("Failed to decode response: \(decodingError)")
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Error Types

enum ApiError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case unauthorized
    case networkError(String)
    case serverError(String)
    case backendError(statusCode: Int, code: String, message: String, retryable: Bool)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized access"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .backendError(_, let code, let message, _):
            return "\(code): \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var statusCode: Int? {
        switch self {
        case .backendError(let statusCode, _, _, _):
            return statusCode
        default:
            return nil
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .backendError(_, _, _, let retryable):
            return retryable
        case .networkError:
            return true
        case .serverError:
            return true
        default:
            return false
        }
    }
}
