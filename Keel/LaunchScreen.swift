import SwiftUI

/// Launch screen that mirrors the splash gradient for fast perceived loading
/// 
/// Features:
/// - Identical gradient background to SplashView
/// - Minimal "K" icon for instant recognition
/// - Fast perceived load time
/// - Consistent with green theme
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background gradient (identical to SplashView)
            backgroundGradient
                .ignoresSafeArea()
            
            // Minimal "K" icon
            VStack(spacing: AppTheme.spacingS) {
                // App Icon
                ZStack {
                    // Icon background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // "K" letter
                    Text("K")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(AppTheme.primaryGreen)
                        .tracking(1.0)
                }
                
                // App name
                Text(AppTheme.appName)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .tracking(1.0)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Private Properties
    
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
}

// MARK: - Preview

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
