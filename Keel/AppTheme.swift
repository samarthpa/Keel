import SwiftUI

/// Keel App Theme System
/// 
/// A comprehensive theming system for the Keel app with consistent colors,
/// typography, and branding elements.
/// 
/// Branding:
/// - App Name: "Keel"
/// - Tagline: "The smarter way to use your credit cards."
/// - Primary Color: Keel Green (#22C55E)
struct AppTheme {
    
    // MARK: - Colors
    
    /// Primary brand color - Keel Green
    static let primaryGreen = Color("KeelGreen")
    
    /// Darker variant of primary green for contrast
    static let primaryGreenDark = Color("KeelGreenDark")
    
    /// Background color for the app
    static let background = Color("Background")
    
    /// Surface color for cards and elevated elements
    static let surface = Color("Surface")
    
    /// Primary text color
    static let textPrimary = Color("TextPrimary")
    
    /// Secondary text color for less important information
    static let textSecondary = Color("TextSecondary")
    
    /// Accent color for highlights and interactive elements
    static let accent = Color("Accent")
    
    /// Success color for positive states
    static let success = Color("Success")
    
    /// Warning color for caution states
    static let warning = Color("Warning")
    
    /// Error color for negative states
    static let error = Color("Error")
    
    /// Divider color for separators
    static let divider = Color("Divider")
    
    // MARK: - Typography
    
    /// Large headline text (e.g., main screen titles)
    static let headline = Font.system(size: 32, weight: .bold, design: .default)
    
    /// Medium headline text (e.g., section headers)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    
    /// Small headline text (e.g., card titles)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    /// Title text (e.g., navigation titles)
    static let title = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// Medium title text
    static let titleMedium = Font.system(size: 18, weight: .medium, design: .default)
    
    /// Small title text
    static let titleSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    /// Body text (e.g., main content)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Medium body text
    static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Small body text
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Caption text (e.g., metadata, footnotes)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Small caption text
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    
    /// Button text
    static let button = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Small button text
    static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Spacing
    
    /// Extra small spacing (4pt)
    static let spacingXS: CGFloat = 4
    
    /// Small spacing (8pt)
    static let spacingS: CGFloat = 8
    
    /// Medium spacing (16pt)
    static let spacingM: CGFloat = 16
    
    /// Large spacing (24pt)
    static let spacingL: CGFloat = 24
    
    /// Extra large spacing (32pt)
    static let spacingXL: CGFloat = 32
    
    /// Extra extra large spacing (48pt)
    static let spacingXXL: CGFloat = 48
    
    // MARK: - Corner Radius
    
    /// Small corner radius (4pt)
    static let cornerRadiusS: CGFloat = 4
    
    /// Medium corner radius (8pt)
    static let cornerRadiusM: CGFloat = 8
    
    /// Large corner radius (12pt)
    static let cornerRadiusL: CGFloat = 12
    
    /// Extra large corner radius (16pt)
    static let cornerRadiusXL: CGFloat = 16
    
    // MARK: - Shadows
    
    /// Small shadow for subtle elevation
    static let shadowS = Shadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Medium shadow for moderate elevation
    static let shadowM = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Large shadow for significant elevation
    static let shadowL = Shadow(
        color: Color.black.opacity(0.2),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // MARK: - Branding
    
    /// App name
    static let appName = "Keel"
    
    /// App tagline
    static let tagline = "The smarter way to use your credit cards."
    
    /// App description
    static let description = "Keel helps you maximize your credit card rewards by providing intelligent recommendations based on your location and spending patterns."
}

// MARK: - Shadow Helper

/// Shadow configuration for consistent elevation
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    /// Apply shadow to a view
    func apply(to view: some View) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Apply theme colors with semantic naming
    static let keelPrimary = AppTheme.primaryGreen
    static let keelPrimaryDark = AppTheme.primaryGreenDark
    static let keelBackground = AppTheme.background
    static let keelSurface = AppTheme.surface
    static let keelTextPrimary = AppTheme.textPrimary
    static let keelTextSecondary = AppTheme.textSecondary
    static let keelAccent = AppTheme.accent
    static let keelSuccess = AppTheme.success
    static let keelWarning = AppTheme.warning
    static let keelError = AppTheme.error
    static let keelDivider = AppTheme.divider
}

// MARK: - Font Extensions

extension Font {
    /// Apply theme fonts with semantic naming
    static let keelHeadline = AppTheme.headline
    static let keelHeadlineMedium = AppTheme.headlineMedium
    static let keelHeadlineSmall = AppTheme.headlineSmall
    static let keelTitle = AppTheme.title
    static let keelTitleMedium = AppTheme.titleMedium
    static let keelTitleSmall = AppTheme.titleSmall
    static let keelBody = AppTheme.body
    static let keelBodyMedium = AppTheme.bodyMedium
    static let keelBodySmall = AppTheme.bodySmall
    static let keelCaption = AppTheme.caption
    static let keelCaptionSmall = AppTheme.captionSmall
    static let keelButton = AppTheme.button
    static let keelButtonSmall = AppTheme.buttonSmall
}

// MARK: - View Extensions

extension View {
    /// Apply theme background
    func keelBackground() -> some View {
        self.background(AppTheme.background)
    }
    
    /// Apply theme surface styling
    func keelSurface() -> some View {
        self
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.cornerRadiusM)
            .shadow(color: AppTheme.shadowS.color, radius: AppTheme.shadowS.radius, x: AppTheme.shadowS.x, y: AppTheme.shadowS.y)
    }
    
    /// Apply primary button styling
    func keelPrimaryButton() -> some View {
        self
            .font(AppTheme.button)
            .foregroundColor(.white)
            .background(AppTheme.primaryGreen)
            .cornerRadius(AppTheme.cornerRadiusM)
            .padding(.horizontal, AppTheme.spacingM)
            .padding(.vertical, AppTheme.spacingS)
    }
    
    /// Apply secondary button styling
    func keelSecondaryButton() -> some View {
        self
            .font(AppTheme.button)
            .foregroundColor(AppTheme.primaryGreen)
            .background(AppTheme.primaryGreen.opacity(0.1))
            .cornerRadius(AppTheme.cornerRadiusM)
            .padding(.horizontal, AppTheme.spacingM)
            .padding(.vertical, AppTheme.spacingS)
    }
}

// MARK: - Text Extensions

extension Text {
    /// Apply headline styling
    func keelHeadline() -> some View {
        self.font(AppTheme.headline)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply headline medium styling
    func keelHeadlineMedium() -> some View {
        self.font(AppTheme.headlineMedium)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply headline small styling
    func keelHeadlineSmall() -> some View {
        self.font(AppTheme.headlineSmall)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply title styling
    func keelTitle() -> some View {
        self.font(AppTheme.title)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply title medium styling
    func keelTitleMedium() -> some View {
        self.font(AppTheme.titleMedium)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply title small styling
    func keelTitleSmall() -> some View {
        self.font(AppTheme.titleSmall)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply body styling
    func keelBody() -> some View {
        self.font(AppTheme.body)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply body medium styling
    func keelBodyMedium() -> some View {
        self.font(AppTheme.bodyMedium)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply body small styling
    func keelBodySmall() -> some View {
        self.font(AppTheme.bodySmall)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    /// Apply caption styling
    func keelCaption() -> some View {
        self.font(AppTheme.caption)
            .foregroundColor(AppTheme.textSecondary)
    }
    
    /// Apply caption small styling
    func keelCaptionSmall() -> some View {
        self.font(AppTheme.captionSmall)
            .foregroundColor(AppTheme.textSecondary)
    }
}
