# Keel iOS App

A SwiftUI-based iOS application for intelligent credit card recommendations based on merchant visits and location data.

## 🎨 Design System

### Theme Overview

The app uses a comprehensive design system built around a green color palette with consistent spacing, typography, and component styling.

#### Color Tokens

```swift
// Primary Colors
AppTheme.primaryGreen      // #22C55E - Main brand color
AppTheme.primaryGreenDark  // Darker variant for contrast

// Background Colors
AppTheme.background        // Main app background
AppTheme.surface          // Card and component backgrounds

// Text Colors
AppTheme.textPrimary      // Primary text color
AppTheme.textSecondary    // Secondary text color

// Semantic Colors
AppTheme.success          // Success states and positive feedback
AppTheme.warning          // Warning states and cautions
AppTheme.error           // Error states and negative feedback
AppTheme.accent          // Accent color for highlights

// Utility Colors
AppTheme.divider          // Border and separator lines
```

#### Typography

```swift
// Headlines
AppTheme.headline         // Large headlines (32pt, bold)
AppTheme.headlineSmall    // Medium headlines (24pt, semibold)

// Titles
AppTheme.title            // Section titles (20pt, semibold)
AppTheme.titleSmall       // Subsection titles (18pt, medium)

// Body Text
AppTheme.body             // Primary body text (16pt, regular)
AppTheme.bodyMedium       // Emphasized body text (16pt, medium)
AppTheme.bodySmall        // Smaller body text (14pt, regular)

// Captions
AppTheme.caption          // Secondary text (12pt, regular)
AppTheme.captionSmall     // Fine print (10pt, regular)
```

#### Spacing

```swift
AppTheme.spacingXS        // 4pt - Tight spacing
AppTheme.spacingS         // 8pt - Small spacing
AppTheme.spacingM         // 16pt - Medium spacing
AppTheme.spacingL         // 24pt - Large spacing
AppTheme.spacingXL        // 32pt - Extra large spacing
```

#### Component Styling

```swift
AppTheme.cornerRadiusS    // 4pt - Small radius
AppTheme.cornerRadiusM    // 8pt - Medium radius
AppTheme.cornerRadiusL    // 12pt - Large radius

AppTheme.shadowS          // Subtle shadows
AppTheme.shadowM          // Medium shadows
AppTheme.shadowL          // Large shadows
```

## 🔄 App Flow

### Navigation Architecture

The app follows a state-driven navigation pattern:

```
SplashView (3s) → AuthFlowView → MainTabView
     ↓              ↓              ↓
AppRootView manages transitions based on SessionManager.isAuthenticated
```

#### 1. SplashView
- **Duration**: 3 seconds with tap-to-skip
- **Purpose**: Brand introduction and app initialization
- **Features**: Animated "Keel" wordmark, gradient background
- **Transition**: Automatic to AuthFlowView or MainTabView

#### 2. AuthFlowView
- **Purpose**: User authentication (Sign Up/Log In)
- **Features**: 
  - Segmented control for Sign Up/Log In
  - Real-time email/password validation
  - Loading states and error banners
  - Haptic feedback on success/failure
- **Success**: Stores JWT token in Keychain, navigates to MainTabView

#### 3. MainTabView
- **Tabs**: Home, History, Cards, Settings, Profile
- **Features**: SF Symbols icons, green accent color
- **Navigation**: Tab-based with smooth transitions

## 🚀 Setup Instructions

### Prerequisites

- Xcode 14.0+
- iOS 16.0+
- FastAPI backend running locally (see `server/README.md`)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Keel
   ```

2. **Open the project**
   ```bash
   open Keel.xcodeproj
   ```

3. **Build and run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

### Backend Configuration

#### Setting Base URL

The app connects to your local FastAPI backend. You'll need to expose it via ngrok for device testing:

1. **Start your FastAPI server**
   ```bash
   cd server
   make dev
   ```

2. **Expose with ngrok**
   ```bash
   ngrok http 8000
   ```

3. **Update Base URL in app**
   - Open the app
   - Go to **Settings** tab
   - Enter your ngrok URL: `https://your-ngrok-url.ngrok.io`
   - Tap "Test Connection" to verify

#### Local Development

For simulator testing, you can use:
- **Local**: `https://127.0.0.1:8000`
- **Network**: `https://your-local-ip:8000`

### Authentication Setup

#### Register/Login Flow

1. **Start the app**
   - App will show SplashView for 3 seconds
   - Tap to skip or wait for automatic transition

2. **Create account**
   - Select "Sign Up" tab
   - Enter email and password (min 8 characters)
   - Tap "Create Account"
   - App will call `POST /auth/register`

3. **Login**
   - Select "Log In" tab
   - Enter credentials
   - Tap "Log In"
   - App will call `POST /auth/login`

#### Token Storage

- **Location**: iOS Keychain (`com.keel.auth`)
- **Key**: `keel_jwt_token`
- **Security**: Encrypted storage, persists across app launches
- **Auto-refresh**: Automatic token validation on app start

#### Logout Process

1. **Manual logout**
   - Go to **Settings** tab
   - Tap "Logout" button
   - App clears Keychain and returns to AuthFlowView

2. **Automatic logout**
   - 401 Unauthorized responses trigger auto-logout
   - SessionManager handles token invalidation
   - User redirected to AuthFlowView

## 🧪 Testing Features

### Simulate Visit

The app includes a simulation mode for testing without real location data:

1. **Enable simulation**
   - Go to **Settings** tab
   - Toggle "Use Mock Visits in Simulator"
   - Return to **Home** tab

2. **Simulate visit**
   - Tap "Simulate Visit" button
   - App calls `POST /v1/mock/visit` with Starbucks data
   - Then calls `POST /v1/score` for recommendations
   - Results displayed in "Last Recommendation" card

3. **View results**
   - Recommendation shows merchant, card, confidence, reason
   - Tap "View History" to see visit details
   - History shows top-3 card rankings

### Location Testing

#### Device Testing

For real device testing with location:

1. **Enable location**
   - App requests location permission on first use
   - Go to **Settings** tab if permission denied
   - Tap "Enable Location" button

2. **Location features**
   - Real-time location tracking via LocationManager
   - Automatic visit processing when location changes
   - Background location updates (when app is active)

#### Simulator Limitations

- **CLVisit**: iOS Simulator doesn't provide real CLVisit data
- **Location accuracy**: Simulated locations may not trigger visit detection
- **Background updates**: Limited background location in simulator
- **Recommendation**: Use "Simulate Visit" for testing in simulator

### Debug Features

#### Request Tracking

- **Request IDs**: Each API call gets a unique request ID
- **Debug View**: Available in Settings tab (Debug Mode toggle)
- **Error logging**: Detailed error messages and stack traces
- **Network status**: Real-time API connection status

#### Development Tools

- **Mock visits**: Simulate merchant visits without location
- **Config display**: Show server configuration values
- **Raw JSON**: Toggle raw API responses in detail views
- **Request logs**: Track API calls and responses

## 📱 App Features

### Home Tab

- **Last Recommendation**: Shows most recent card recommendation
- **API Status**: Real-time connection status indicator
- **Quick Actions**: Simulate visit or location management
- **Welcome Message**: Personalized greeting with user email

### History Tab

- **Visit List**: Chronological list of merchant visits
- **Search**: Filter by merchant, card, or category
- **Filters**: Merchant and card-based filtering
- **Detail View**: Top-3 card rankings with reasons

### Cards Tab

- **Card Management**: Add, remove, enable/disable cards
- **Local Storage**: Cards persisted in UserDefaults
- **Card Types**: Support for Visa, Mastercard, Amex, Discover
- **Toggle Controls**: Enable/disable cards for recommendations

### Settings Tab

- **API Configuration**: Base URL with validation
- **Connection Testing**: Test API connectivity
- **Server Config**: Display rules_version, model_version, etc.
- **Debug Options**: Mock visits, request IDs, debug mode
- **Logout**: Secure session termination

### Profile Tab

- **User Info**: Email and account creation date
- **App Version**: Current app version and build number
- **Support Links**: Feedback and App Store rating
- **Account Management**: User profile from `/auth/me`

## 🔧 Development Notes

### Architecture

- **SwiftUI**: Declarative UI framework
- **Combine**: Reactive programming for data flow
- **Core Data**: Local data persistence (for future visits)
- **Keychain Services**: Secure token storage
- **Location Services**: Core Location for visit detection

### State Management

- **SessionManager**: Authentication state and token management
- **ApiClient**: Network requests with error handling
- **LocationManager**: Location services and visit detection
- **AppTheme**: Centralized design system

### Error Handling

- **ApiError**: Structured error types with retry logic
- **ErrorBanner**: Dismissible error display with retry
- **Loading States**: Progress indicators for async operations
- **Empty States**: Contextual empty state components

### Testing Strategy

- **Simulator**: Use mock visits for API testing
- **Device**: Real location testing with CLVisit
- **Unit Tests**: ApiClient and SessionManager tests
- **UI Tests**: Authentication flow and tab navigation

## 🚨 Known Limitations

### Location Services

- **CLVisit**: Requires significant location changes to trigger
- **Background**: Limited background location in iOS
- **Accuracy**: Location accuracy affects visit detection
- **Simulator**: No real CLVisit data in iOS Simulator

### API Dependencies

- **Backend**: Requires FastAPI server running
- **Network**: Internet connection required for recommendations
- **Authentication**: JWT tokens expire and require refresh
- **Rate Limits**: API may have rate limiting

### Device Compatibility

- **iOS Version**: Requires iOS 16.0+
- **Location**: Requires location permission
- **Keychain**: Requires device with Keychain support
- **Network**: Requires internet connectivity

## 📚 Additional Resources

- **Backend API**: See `server/README.md` for API documentation
- **Design System**: `AppTheme.swift` for complete theming
- **API Client**: `ApiClient.swift` for network layer
- **Session Management**: `SessionManager.swift` for auth
- **Location Services**: `LocationManager.swift` for visits

## 🤝 Contributing

1. Follow the existing code style and architecture
2. Use the established design system (AppTheme)
3. Add appropriate error handling and loading states
4. Include accessibility labels and hints
5. Test on both simulator and device
6. Update this README for new features

---

**Note**: This app is designed for development and testing purposes. Production deployment would require additional security measures, error handling, and user experience refinements.
