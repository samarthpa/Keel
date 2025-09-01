import SwiftUI
import Combine

/// Debug view for showcasing API request tracking and debugging
/// 
/// Features:
/// - Display current request ID
/// - Show API error details
/// - Network request logging
/// - Debug information panel
struct DebugView: View {
    @StateObject private var apiClient = ApiClient.shared
    @State private var requestLogs: [RequestLog] = []
    @State private var showDebugPanel = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacingM) {
                // Debug Toggle
                HStack {
                    Text("Debug Mode")
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $showDebugPanel)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                }
                .padding(.horizontal, AppTheme.spacingM)
                
                if showDebugPanel {
                    debugPanel
                }
                
                Spacer()
                
                // Test API Calls
                VStack(spacing: AppTheme.spacingM) {
                    Text("Test API Calls")
                        .keelTitleSmall()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Button("Test Login") {
                        testLogin()
                    }
                    .keelPrimaryButton()
                    
                    Button("Test Register") {
                        testRegister()
                    }
                    .keelSecondaryButton()
                    
                    Button("Test Me Endpoint") {
                        testMe()
                    }
                    .keelSecondaryButton()
                    
                    Button("Test Error") {
                        testError()
                    }
                    .keelSecondaryButton()
                }
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.bottom, AppTheme.spacingL)
            }
            .keelBackground()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.large)
        }
        .onReceive(apiClient.$currentRequestID) { requestID in
            if let requestID = requestID {
                addRequestLog(requestID: requestID, action: "Request Started")
            }
        }
        .onReceive(apiClient.$lastError) { error in
            if let error = error {
                addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Debug Panel
    
    private var debugPanel: some View {
        VStack(spacing: AppTheme.spacingM) {
            // Current Request ID
            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Current Request ID")
                    .keelBodyMedium()
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(apiClient.currentRequestID ?? "None")
                    .keelCaption()
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(AppTheme.spacingS)
                    .background(AppTheme.surface)
                    .cornerRadius(AppTheme.cornerRadiusS)
            }
            
            // Last Error
            if let error = apiClient.lastError {
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("Last Error")
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text(error.localizedDescription)
                            .keelCaption()
                            .foregroundColor(AppTheme.error)
                        
                        if let statusCode = error.statusCode {
                            Text("Status: \(statusCode)")
                                .keelCaptionSmall()
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Text("Retryable: \(error.isRetryable ? "Yes" : "No")")
                            .keelCaptionSmall()
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(AppTheme.spacingS)
                    .background(AppTheme.error.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadiusS)
                }
            }
            
            // Request Logs
            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                HStack {
                    Text("Request Logs")
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button("Clear") {
                        requestLogs.removeAll()
                    }
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.primaryGreen)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        ForEach(requestLogs.reversed(), id: \.id) { log in
                            RequestLogView(log: log)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding(AppTheme.spacingS)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.cornerRadiusS)
            }
        }
        .padding(AppTheme.spacingM)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusM)
        .padding(.horizontal, AppTheme.spacingM)
    }
    
    // MARK: - Test Methods
    
    private func testLogin() {
        apiClient.login(email: "test@example.com", password: "wrongpassword")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Login Failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { response in
                    addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Login Success: \(response.email)")
                }
            )
            .store(in: &apiClient.cancellables)
    }
    
    private func testRegister() {
        apiClient.register(email: "test@example.com", password: "TestPass123!")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Register Failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { response in
                    addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Register Success: \(response.email)")
                }
            )
            .store(in: &apiClient.cancellables)
    }
    
    private func testMe() {
        apiClient.me()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Me Failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { response in
                    addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Me Success: \(response.email)")
                }
            )
            .store(in: &apiClient.cancellables)
    }
    
    private func testError() {
        // Test with invalid endpoint to trigger error
        apiClient.get(endpoint: "/invalid/endpoint")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Error Test: \(error.localizedDescription)")
                    }
                },
                receiveValue: { (_: EmptyResponse) in
                    addRequestLog(requestID: apiClient.currentRequestID ?? "unknown", action: "Error Test Success")
                }
            )
            .store(in: &apiClient.cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func addRequestLog(requestID: String, action: String) {
        let log = RequestLog(
            id: UUID().uuidString,
            requestID: requestID,
            action: action,
            timestamp: Date()
        )
        requestLogs.append(log)
        
        // Keep only last 50 logs
        if requestLogs.count > 50 {
            requestLogs.removeFirst()
        }
    }
}

// MARK: - Supporting Types

struct RequestLog: Identifiable {
    let id: String
    let requestID: String
    let action: String
    let timestamp: Date
}

struct RequestLogView: View {
    let log: RequestLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            HStack {
                Text(log.requestID)
                    .keelCaptionSmall()
                    .foregroundColor(AppTheme.primaryGreen)
                    .font(.system(size: 12, design: .monospaced))
                
                Spacer()
                
                Text(log.timestamp, style: .time)
                    .keelCaptionSmall()
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Text(log.action)
                .keelCaptionSmall()
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(AppTheme.spacingXS)
        .background(AppTheme.background)
        .cornerRadius(AppTheme.cornerRadiusS)
    }
}

// MARK: - Preview

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
