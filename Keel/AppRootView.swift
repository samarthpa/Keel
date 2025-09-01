

import SwiftUI

// MARK: - Empty State Component

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let ctaTitle: String?
    let ctaAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaAction = ctaAction
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacingL) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppTheme.textSecondary)
                .accessibilityHidden(true)
            
            // Content
            VStack(spacing: AppTheme.spacingM) {
                Text(title)
                    .keelTitleSmall()
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .keelBody()
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Call to Action (optional)
            if let ctaTitle = ctaTitle, let ctaAction = ctaAction {
                Button(ctaTitle, action: ctaAction)
                    .keelPrimaryButton()
                    .accessibilityLabel("\(title) - \(ctaTitle)")
            }
        }
        .padding(AppTheme.spacingXL)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(message)")
        .accessibilityHint(ctaTitle != nil ? "Tap to \(ctaTitle?.lowercased() ?? "")" : "")
    }
}



// MARK: - Loading State Component

struct LoadingStateView: View {
    let message: String
    let showSpinner: Bool
    
    init(message: String = "Loading...", showSpinner: Bool = true) {
        self.message = message
        self.showSpinner = showSpinner
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            if showSpinner {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                    .scaleEffect(1.2)
                    .accessibilityHidden(true)
            }
            
            Text(message)
                .keelBody()
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.spacingXL)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading: \(message)")
    }
}

// MARK: - Success State Component

struct SuccessStateView: View {
    let icon: String
    let title: String
    let message: String
    let ctaTitle: String?
    let ctaAction: (() -> Void)?
    
    init(
        icon: String = "checkmark.circle.fill",
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaAction = ctaAction
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacingL) {
            // Success Icon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppTheme.success)
                .accessibilityHidden(true)
            
            // Content
            VStack(spacing: AppTheme.spacingM) {
                Text(title)
                    .keelTitleSmall()
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .keelBody()
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Call to Action (optional)
            if let ctaTitle = ctaTitle, let ctaAction = ctaAction {
                Button(ctaTitle, action: ctaAction)
                    .keelPrimaryButton()
                    .accessibilityLabel("\(title) - \(ctaTitle)")
            }
        }
        .padding(AppTheme.spacingXL)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Success: \(title) - \(message)")
        .accessibilityHint(ctaTitle != nil ? "Tap to \(ctaTitle?.lowercased() ?? "")" : "")
    }
}

// MARK: - Info Banner Component

struct InfoBanner: View {
    let title: String
    let message: String
    let icon: String
    let onDismiss: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: AppTheme.spacingM) {
                // Info Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                    .accessibilityHidden(true)
                
                // Content
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text(title)
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(message)
                        .keelCaption()
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Dismiss Button
                Button("Dismiss") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
                .keelCaption()
                .foregroundColor(AppTheme.accent)
                .accessibilityLabel("Dismiss info")
            }
            .padding(AppTheme.spacingM)
            .background(AppTheme.accent.opacity(0.05))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.accent.opacity(0.2)),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Info: \(title) - \(message)")
            .accessibilityHint("Double tap to dismiss")
        }
    }
}

// MARK: - Warning Banner Component

struct WarningBanner: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    let actionTitle: String?
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: AppTheme.spacingM) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.warning)
                    .accessibilityHidden(true)
                
                // Content
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text(title)
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(message)
                        .keelCaption()
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: AppTheme.spacingS) {
                    if let onAction = onAction, let actionTitle = actionTitle {
                        Button(actionTitle) {
                            onAction()
                        }
                        .keelCaption()
                        .foregroundColor(AppTheme.warning)
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(AppTheme.warning.opacity(0.1))
                        .cornerRadius(AppTheme.cornerRadiusS)
                        .accessibilityLabel("\(actionTitle) action")
                    }
                    
                    Button("Dismiss") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }
                    .keelCaption()
                    .foregroundColor(AppTheme.warning)
                    .accessibilityLabel("Dismiss warning")
                }
            }
            .padding(AppTheme.spacingM)
            .background(AppTheme.warning.opacity(0.05))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.warning.opacity(0.2)),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Warning: \(title) - \(message)")
            .accessibilityHint("Double tap to dismiss")
        }
    }
}
