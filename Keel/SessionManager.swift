import Foundation
import Security
import Combine
import SwiftUI

/// Session manager for handling authentication state and JWT tokens
/// 
/// Features:
/// - Secure JWT token storage in Keychain
/// - Authentication state management with Combine publishers
/// - API integration for login/register/logout
/// - Automatic token loading on app start
/// - 401 handling with auto-logout
class SessionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: User?
    
    // MARK: - Private Properties
    
    var cancellables = Set<AnyCancellable>()
    private let apiClient = ApiClient.shared
    private let keychainService = "com.keel.auth"
    private let tokenKey = "keel_jwt_token"
    private let userKey = "keel_user_data"
    
    // MARK: - Initialization
    
    init() {
        loadStoredSession()
        setupApiClientErrorHandling()
    }
    
    // MARK: - Public Methods
    
    /// Login with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Publisher that emits authentication result
    func login(email: String, password: String) -> AnyPublisher<AuthResult, ApiError> {
        isLoading = true
        
        return apiClient.login(email: email, password: password)
            .handleEvents(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            })
            .map { [weak self] response in
                self?.handleSuccessfulAuth(response: response)
                return AuthResult.success(response)
            }
            .catch { [weak self] error in
                self?.handleAuthError(error)
                return Fail<AuthResult, ApiError>(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Register with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Publisher that emits authentication result
    func register(email: String, password: String) -> AnyPublisher<AuthResult, ApiError> {
        isLoading = true
        
        return apiClient.register(email: email, password: password)
            .handleEvents(receiveCompletion: { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            })
            .map { [weak self] response in
                self?.handleSuccessfulAuth(response: response)
                return AuthResult.success(response)
            }
            .catch { [weak self] error in
                self?.handleAuthError(error)
                return Fail<AuthResult, ApiError>(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Logout and clear session
    func logout() {
        isLoading = true
        
        // Call logout endpoint if we have a token
        if let token = getStoredToken() {
            apiClient.setToken(token)
            apiClient.logout()
                .sink(
                    receiveCompletion: { [weak self] completion in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            self?.clearSession()
                        }
                    },
                    receiveValue: { _ in
                        // Logout successful
                    }
                )
                .store(in: &cancellables)
        } else {
            // No token to logout, just clear session
            clearSession()
            isLoading = false
        }
    }
    
    /// Get current access token
    /// - Returns: Current JWT token or nil if not authenticated
    func getAccessToken() -> String? {
        return getStoredToken()
    }
    
    /// Check if user is authenticated
    /// - Returns: True if user has valid token
    var isUserAuthenticated: Bool {
        return getStoredToken() != nil
    }
    
    // MARK: - Private Methods
    
    /// Load stored session from Keychain
    private func loadStoredSession() {
        if let token = getStoredToken(),
           let userData = getStoredUserData() {
            // Set token in ApiClient
            apiClient.setToken(token)
            
            // Validate token and load user data
            validateStoredToken(token) { [weak self] isValid in
                DispatchQueue.main.async {
                    if isValid {
                        self?.isAuthenticated = true
                        self?.currentUser = userData
                    } else {
                        self?.clearSession()
                    }
                }
            }
        }
    }
    
    /// Handle successful authentication
    private func handleSuccessfulAuth(response: AuthResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.storeToken(response.access_token)
            self?.storeUserData(response)
            self?.isAuthenticated = true
            self?.currentUser = User(
                id: response.user_id,
                email: response.email,
                created_at: Date()
            )
            
            // Set token in ApiClient for future requests
            self?.apiClient.setToken(response.access_token)
        }
    }
    
    /// Handle authentication errors
    private func handleAuthError(_ error: ApiError) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            // Error is already published by the publisher
        }
    }
    
    /// Setup API client error handling
    private func setupApiClientErrorHandling() {
        apiClient.$lastError
            .compactMap { $0 }
            .sink { [weak self] error in
                if case .unauthorized = error {
                    self?.handleUnauthorizedError()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle 401 unauthorized errors
    private func handleUnauthorizedError() {
        DispatchQueue.main.async { [weak self] in
            self?.clearSession()
            // Show AuthFlowView - this will be handled by the app's navigation
        }
    }
    
    /// Validate stored token
    private func validateStoredToken(_ token: String, completion: @escaping (Bool) -> Void) {
        apiClient.setToken(token)
        apiClient.me()
            .sink(
                receiveCompletion: { _ in
                    // Token validation completed
                },
                receiveValue: { _ in
                    // Token is valid
                }
            )
            .store(in: &cancellables)
    }
    
    /// Clear session data
    private func clearSession() {
        deleteStoredToken()
        deleteStoredUserData()
        isAuthenticated = false
        currentUser = nil
        apiClient.clearToken()
    }
    
    // MARK: - Keychain Methods
    
    /// Store JWT token in Keychain
    private func storeToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing token
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to store token in Keychain: \(status)")
        }
    }
    
    /// Get stored JWT token from Keychain
    private func getStoredToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        
        return nil
    }
    
    /// Delete stored JWT token from Keychain
    private func deleteStoredToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Store user data in UserDefaults
    private func storeUserData(_ response: AuthResponse) {
        let userData = User(
            id: response.user_id,
            email: response.email,
            created_at: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
    
    /// Get stored user data from UserDefaults
    private func getStoredUserData() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    /// Delete stored user data from UserDefaults
    private func deleteStoredUserData() {
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}

// MARK: - Supporting Types

/// Authentication result
enum AuthResult {
    case success(AuthResponse)
    case failure(ApiError)
}

/// User model
struct User: Codable {
    let id: Int
    let email: String
    let created_at: Date
}
