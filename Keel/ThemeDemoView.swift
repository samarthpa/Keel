import SwiftUI

/// Demo view showcasing the Keel theming system
/// 
/// This view demonstrates all the theme components including:
/// - Color palette
/// - Typography
/// - Spacing and layout
/// - Branding elements
struct ThemeDemoView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    // Branding Section
                    brandingSection
                    
                    // Color Palette Section
                    colorPaletteSection
                    
                    // Typography Section
                    typographySection
                    
                    // Component Examples Section
                    componentExamplesSection
                }
                .padding(AppTheme.spacingM)
            }
            .keelBackground()
            .navigationTitle("Keel Theme System")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Branding Section
    
    private var brandingSection: some View {
        VStack(spacing: AppTheme.spacingM) {
            Text(AppTheme.appName)
                .keelHeadline()
                .foregroundColor(AppTheme.primaryGreen)
            
            Text(AppTheme.tagline)
                .keelBody()
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(AppTheme.description)
                .keelCaption()
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppTheme.spacingL)
        .keelSurface()
    }
    
    // MARK: - Color Palette Section
    
    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Color Palette")
                .keelTitle()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.spacingS) {
                ColorSwatch(name: "Primary Green", color: AppTheme.primaryGreen)
                ColorSwatch(name: "Primary Dark", color: AppTheme.primaryGreenDark)
                ColorSwatch(name: "Background", color: AppTheme.background)
                ColorSwatch(name: "Surface", color: AppTheme.surface)
                ColorSwatch(name: "Text Primary", color: AppTheme.textPrimary)
                ColorSwatch(name: "Text Secondary", color: AppTheme.textSecondary)
                ColorSwatch(name: "Accent", color: AppTheme.accent)
                ColorSwatch(name: "Success", color: AppTheme.success)
                ColorSwatch(name: "Warning", color: AppTheme.warning)
                ColorSwatch(name: "Error", color: AppTheme.error)
                ColorSwatch(name: "Divider", color: AppTheme.divider)
            }
        }
        .padding(AppTheme.spacingL)
        .keelSurface()
    }
    
    // MARK: - Typography Section
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Typography")
                .keelTitle()
            
            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Headline (32pt Bold)")
                    .keelHeadline()
                
                Text("Headline Medium (28pt Semibold)")
                    .font(AppTheme.headlineMedium)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Headline Small (24pt Semibold)")
                    .font(AppTheme.headlineSmall)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Title (20pt Semibold)")
                    .keelTitle()
                
                Text("Title Medium (18pt Medium)")
                    .font(AppTheme.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Title Small (16pt Medium)")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Body (16pt Regular)")
                    .keelBody()
                
                Text("Body Medium (14pt Medium)")
                    .font(AppTheme.bodyMedium)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Body Small (12pt Regular)")
                    .font(AppTheme.bodySmall)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Caption (12pt Regular)")
                    .keelCaption()
                
                Text("Caption Small (10pt Regular)")
                    .font(AppTheme.captionSmall)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text("Button (16pt Semibold)")
                    .font(AppTheme.button)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Button Small (14pt Medium)")
                    .font(AppTheme.buttonSmall)
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(AppTheme.spacingL)
        .keelSurface()
    }
    
    // MARK: - Component Examples Section
    
    private var componentExamplesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Component Examples")
                .keelTitle()
            
            VStack(spacing: AppTheme.spacingM) {
                // Primary Button
                Button("Primary Button") {
                    // Action
                }
                .keelPrimaryButton()
                
                // Secondary Button
                Button("Secondary Button") {
                    // Action
                }
                .keelSecondaryButton()
                
                // Card Example
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("Sample Card")
                        .keelTitleSmall()
                    
                    Text("This is a sample card component using the theme system.")
                        .keelBody()
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(AppTheme.spacingM)
                .keelSurface()
                
                // Status Indicators
                HStack(spacing: AppTheme.spacingM) {
                    StatusIndicator(title: "Success", color: AppTheme.success)
                    StatusIndicator(title: "Warning", color: AppTheme.warning)
                    StatusIndicator(title: "Error", color: AppTheme.error)
                }
            }
        }
        .padding(AppTheme.spacingL)
        .keelSurface()
    }
}

// MARK: - Supporting Views

/// Color swatch component for displaying theme colors
struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.spacingXS) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
            
            Text(name)
                .font(AppTheme.captionSmall)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// Status indicator component
struct StatusIndicator: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.spacingXS) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(AppTheme.captionSmall)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, AppTheme.spacingS)
        .padding(.vertical, AppTheme.spacingXS)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cornerRadiusS)
    }
}

// MARK: - Preview

struct ThemeDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeDemoView()
    }
}
