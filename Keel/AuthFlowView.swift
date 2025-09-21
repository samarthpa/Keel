import SwiftUI
import Security
import Combine

/// Streamlined authentication flow with enhanced validation and UX
/// 
/// Features:
/// - Email format validation with inline errors
/// - Password strength hints and validation
/// - Loading states with spinners
/// - Error banners with green theme styling
/// - Haptic feedback on success/failure
/// - Full accessibility support with VoiceOver
struct AuthFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab = 0 // 0 = Sign Up, 1 = Log In
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var authError: String?
    @State private var showErrorBanner = false
    
    // Validation states
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var isEmailValid = false
    @State private var isPasswordValid = false
    @State private var isConfirmPasswordValid = false
    
    // Haptic feedback
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacingXL) {
                        // Subtle Keel branding
                        VStack(spacing: AppTheme.spacingS) {
                            Text(AppTheme.appName)
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.primaryGreen)
                                .opacity(0.8)
                                .accessibilityLabel("Keel app logo")
                            
                            Text(AppTheme.tagline)
                                .keelCaption()
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("App tagline")
                        }
                        .padding(.top, AppTheme.spacingL)
                        
                        // Segmented Control
                        Picker("Authentication Mode", selection: $selectedTab) {
                            Text("Sign Up").tag(0)
                            Text("Log In").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, AppTheme.spacingM)
                        .accessibilityLabel("Choose between sign up and log in")
                        .onChange(of: selectedTab) { _ in
                            clearAllErrors()
                        }
                        
                        // Form Fields
                        VStack(spacing: AppTheme.spacingM) {
                            // Email Field
                            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                Text("Email")
                                    .keelBodyMedium()
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: email) { _ in
                                        validateEmail()
                                        clearAuthError()
                                    }
                                    .accessibilityLabel("Email address field")
                                    .accessibilityHint("Enter your email address")
                                    .accessibilityValue(isEmailValid ? "Valid email" : "Invalid email")
                                
                                if !emailError.isEmpty {
                                    HStack(spacing: AppTheme.spacingXS) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(AppTheme.error)
                                            .font(.caption)
                                        
                                        Text(emailError)
                                            .keelCaptionSmall()
                                            .foregroundColor(AppTheme.error)
                                    }
                                    .accessibilityLabel("Email validation error: \(emailError)")
                                }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                Text("Password")
                                    .keelBodyMedium()
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                SecureField(selectedTab == 0 ? "Create a password" : "Enter your password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: password) { _ in
                                        validatePassword()
                                        clearAuthError()
                                    }
                                    .accessibilityLabel("Password field")
                                    .accessibilityHint(selectedTab == 0 ? "Create a password with at least 8 characters" : "Enter your password")
                                    .accessibilityValue(isPasswordValid ? "Valid password" : "Invalid password")
                                
                                if selectedTab == 0 {
                                    // Password strength hint
                                    HStack(spacing: AppTheme.spacingXS) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(AppTheme.textSecondary)
                                            .font(.caption)
                                        
                                        Text("Minimum 8 characters")
                                            .keelCaptionSmall()
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .accessibilityLabel("Password requirement: minimum 8 characters")
                                }
                                
                                if !passwordError.isEmpty {
                                    HStack(spacing: AppTheme.spacingXS) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(AppTheme.error)
                                            .font(.caption)
                                        
                                        Text(passwordError)
                                            .keelCaptionSmall()
                                            .foregroundColor(AppTheme.error)
                                    }
                                    .accessibilityLabel("Password validation error: \(passwordError)")
                                }
                            }
                            
                            // Confirm Password Field (Sign Up only)
                            if selectedTab == 0 {
                                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                    Text("Confirm Password")
                                        .keelBodyMedium()
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: confirmPassword) { _ in
                                            validateConfirmPassword()
                                            clearAuthError()
                                        }
                                        .accessibilityLabel("Confirm password field")
                                        .accessibilityHint("Confirm your password")
                                        .accessibilityValue(isConfirmPasswordValid ? "Passwords match" : "Passwords do not match")
                                    
                                    if !confirmPasswordError.isEmpty {
                                        HStack(spacing: AppTheme.spacingXS) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(AppTheme.error)
                                                .font(.caption)
                                            
                                            Text(confirmPasswordError)
                                                .keelCaptionSmall()
                                                .foregroundColor(AppTheme.error)
                                        }
                                        .accessibilityLabel("Confirm password validation error: \(confirmPasswordError)")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.spacingM)
                        
                        Spacer()
                        
                        // Action Button
                        Button(selectedTab == 0 ? "Create Account" : "Log In") {
                            performAuthentication()
                        }
                        .keelPrimaryButton()
                        .disabled(!isFormValid() || sessionManager.isLoading)
                        .padding(.horizontal, AppTheme.spacingM)
                        .accessibilityLabel(selectedTab == 0 ? "Create account button" : "Log in button")
                        .accessibilityHint(isFormValid() ? "Tap to proceed" : "Please fill in all required fields")
                        .accessibilityValue(sessionManager.isLoading ? "Loading" : "Ready")
                        .overlay(
                            Group {
                                if sessionManager.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        
                                        Text(sessionManager.isLoading ? "Processing..." : "")
                                            .keelCaption()
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        )
                        
                        // TESTING: Bypass Authentication Button
                        if selectedTab == 1 { // Only show on Log In tab
                            Button("🚀 Skip Login (Testing)") {
                                bypassAuthentication()
                            }
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, AppTheme.spacingS)
                            .accessibilityLabel("Skip login for testing")
                        }
                        
                        // Legal Links
                        VStack(spacing: AppTheme.spacingS) {
                            Text("By continuing, you agree to our")
                                .keelCaptionSmall()
                                .foregroundColor(AppTheme.textSecondary)
                            
                            HStack(spacing: AppTheme.spacingXS) {
                                Button("Terms of Service") {
                                    // Open terms
                                }
                                .font(AppTheme.captionSmall)
                                .foregroundColor(AppTheme.primaryGreen)
                                .accessibilityLabel("Terms of service link")
                                
                                Text("and")
                                    .keelCaptionSmall()
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Button("Privacy Policy") {
                                    // Open privacy policy
                                }
                                .font(AppTheme.captionSmall)
                                .foregroundColor(AppTheme.primaryGreen)
                                .accessibilityLabel("Privacy policy link")
                            }
                        }
                        .padding(.bottom, AppTheme.spacingL)
                    }
                }
                
                // Error Banner
                if showErrorBanner, let authError = authError {
                    VStack {
                        ErrorBanner(message: authError) {
                            hideErrorBanner()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
            }
            .navigationBarHidden(true)
        }
        .onReceive(sessionManager.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                hapticFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateEmail() {
        emailError = ""
        isEmailValid = false
        
        if email.isEmpty {
            emailError = "Email is required"
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        } else {
            isEmailValid = true
        }
    }
    
    private func validatePassword() {
        passwordError = ""
        isPasswordValid = false
        
        if password.isEmpty {
            passwordError = "Password is required"
        } else if selectedTab == 0 && password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else if selectedTab == 0 && !isValidPassword(password) {
            passwordError = "Password must contain uppercase, number, and special character"
        } else {
            isPasswordValid = true
        }
    }
    
    private func validateConfirmPassword() {
        confirmPasswordError = ""
        isConfirmPasswordValid = false
        
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        } else if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
        } else {
            isConfirmPasswordValid = true
        }
    }
    
    private func isFormValid() -> Bool {
        if selectedTab == 0 {
            // Sign Up validation
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !confirmPassword.isEmpty &&
                   emailError.isEmpty &&
                   passwordError.isEmpty &&
                   confirmPasswordError.isEmpty
        } else {
            // Log In validation
            return !email.isEmpty && 
                   !password.isEmpty &&
                   emailError.isEmpty &&
                   passwordError.isEmpty
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[!@#$%^&*()_+-=\\[\\]{}|;:,.<>?]", options: .regularExpression) != nil
        
        return hasUppercase && hasNumber && hasSpecial
    }
    
    // MARK: - Error Handling Methods
    
    private func clearAllErrors() {
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        authError = nil
        showErrorBanner = false
        isEmailValid = false
        isPasswordValid = false
        isConfirmPasswordValid = false
    }
    
    private func clearAuthError() {
        authError = nil
        showErrorBanner = false
    }
    
    private func showErrorBanner(_ message: String) {
        authError = message
        showErrorBanner = true
        hapticFeedback.impactOccurred()
    }
    
    private func hideErrorBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showErrorBanner = false
        }
    }
    
    // MARK: - Authentication Methods
    
    private func performAuthentication() {
        clearAuthError()
        
        if selectedTab == 0 {
            // Sign Up
            sessionManager.register(email: email, password: password)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            showErrorBanner(error.localizedDescription)
                        }
                    },
                    receiveValue: { result in
                        // Success handled by sessionManager.$isAuthenticated
                        hapticFeedback.impactOccurred()
                    }
                )
                .store(in: &sessionManager.cancellables)
        } else {
            // Log In
            sessionManager.login(email: email, password: password)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            showErrorBanner(error.localizedDescription)
                        }
                    },
                    receiveValue: { result in
                        // Success handled by sessionManager.$isAuthenticated
                        hapticFeedback.impactOccurred()
                    }
                )
                .store(in: &sessionManager.cancellables)
        }
    }
    
    // MARK: - Testing Methods
    
    private func bypassAuthentication() {
        // For testing purposes - bypass the actual authentication
        print("🧪 TESTING: Bypassing authentication...")
        
        // Simulate a successful login by setting the session manager state
        sessionManager.isAuthenticated = true
        sessionManager.currentUser = User(
            id: 123,
            email: "test@example.com",
            created_at: Date()
        )
        
        // Provide haptic feedback
        hapticFeedback.impactOccurred()
        
        print("🧪 TESTING: Authentication bypassed successfully!")
    }
}

// MARK: - Error Banner Component

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.error)
                .font(.title3)
                .accessibilityLabel("Error icon")
            
            // Error Message
            Text(message)
                .keelBody()
                .foregroundColor(AppTheme.error)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Error message: \(message)")
            
            Spacer()
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.error)
                    .font(.title3)
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(AppTheme.spacingM)
        .background(AppTheme.error.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusM)
                .stroke(AppTheme.error.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AppTheme.cornerRadiusM)
        .padding(.horizontal, AppTheme.spacingM)
        .padding(.top, AppTheme.spacingM)
    }
}



// MARK: - Previews

struct AuthFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthFlowView()
            .environmentObject(SessionManager())
    }
}
