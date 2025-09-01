import SwiftUI

/// Splash screen with animated branding and navigation
/// 
/// Features:
/// - Fullscreen green gradient background
/// - Animated "Keel" wordmark
/// - Subtle tagline animation
/// - Automatic navigation after delay
/// - Tap to skip functionality
struct SplashView: View {
    @State private var isAnimating = false
    @State private var showAuthFlow = false
    @EnvironmentObject var sessionManager: SessionManager
    
    // Animation timing
    private let animationDuration: Double = 2.0
    private let navigationDelay: Double = 3.0
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: AppTheme.spacingL) {
                Spacer()
                
                // Animated "Keel" wordmark
                Text(AppTheme.appName)
                    .font(.system(size: 64, weight: .bold, design: .default))
                    .tracking(2.0)
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: animationDuration), value: isAnimating)
                    .accessibilityLabel("Keel app logo")
                
                // Animated tagline
                Text(AppTheme.tagline)
                    .keelBody()
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: animationDuration).delay(0.5), value: isAnimating)
                    .accessibilityLabel("App tagline")
                
                Spacer()
                
                // Tap to skip hint
                Text("Tap to continue")
                    .keelCaption()
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: animationDuration).delay(1.0), value: isAnimating)
                    .accessibilityLabel("Tap to continue hint")
                    .padding(.bottom, AppTheme.spacingL)
            }
            .padding(.horizontal, AppTheme.spacingM)
            
            // Tap area for manual navigation
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    navigateToAuthFlow()
                }
                .accessibilityLabel("Tap to continue to app")
        }
        .onAppear {
            startAnimation()
            scheduleNavigation()
        }
    }
    
    // MARK: - Private Methods
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreenDark
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func startAnimation() {
        isAnimating = true
    }
    
    private func scheduleNavigation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + navigationDelay) {
            navigateToAuthFlow()
        }
    }
    
    private func navigateToAuthFlow() {
        // The AppRootView will handle the navigation based on authentication state
        // This method is called when the splash screen should transition
        // The actual navigation is managed by AppRootView.handleAuthenticationChange
    }
}
