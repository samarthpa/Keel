import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
            
            // Cards Tab
            CardsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Cards")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(AppTheme.primaryGreen)
        .environmentObject(sessionManager)
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var lastRecommendation: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    // Header
                    VStack(spacing: AppTheme.spacingM) {
                        Text("Welcome to Keel")
                            .keelHeadline()
                        
                        Text("Get the best card recommendations for your location")
                            .keelBody()
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.spacingL)
                    
                    // Last Recommendation Card
                    if let recommendation = lastRecommendation {
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Last Recommendation")
                                .keelTitleSmall()
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(recommendation)
                                .keelBody()
                                .foregroundColor(AppTheme.textSecondary)
                                .padding()
                                .background(AppTheme.surface)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        .padding(.horizontal, AppTheme.spacingL)
                    }
                    
                    // Action Buttons
                    VStack(spacing: AppTheme.spacingM) {
                        Button("Simulate Visit") {
                            simulateVisit()
                        }
                        .keelPrimaryButton()
                        .disabled(isLoading)
                        
                        Button("Request Location Permissions") {
                            locationManager.requestPermissions()
                        }
                        .keelSecondaryButton()
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, AppTheme.spacingL)
                    
                    Spacer(minLength: AppTheme.spacingXL)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func simulateVisit() {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastRecommendation = "Amex Gold - Best for dining and groceries"
            isLoading = false
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @State private var visits: [String] = ["Starbucks - Amex Gold", "Target - Chase Freedom", "Gas Station - Citi Custom Cash"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(visits, id: \.self) { visit in
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text(visit)
                            .keelBodyMedium()
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("2 hours ago")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
            }
            .navigationTitle("Visit History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Cards View
struct CardsView: View {
    @State private var cards = [
        ("Amex Gold", true),
        ("Chase Freedom", true),
        ("Citi Custom Cash", false),
        ("Discover It", true)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                            Text(card.0)
                                .keelBodyMedium()
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(card.1 ? "Active" : "Inactive")
                                .keelCaption()
                                .foregroundColor(card.1 ? AppTheme.primaryGreen : AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { card.1 },
                            set: { newValue in
                                cards[index] = (card.0, newValue)
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
            }
            .navigationTitle("My Cards")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var baseURL = "https://localhost:8000"
    @State private var useMockVisits = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("API Configuration") {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Base URL")
                            .keelBodyMedium()
                            .foregroundColor(AppTheme.textPrimary)
                        
                        TextField("https://localhost:8000", text: $baseURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(AppTheme.body)
                    }
                    
                    Button("Test Connection") {
                        // Test API connection
                    }
                    .keelSecondaryButton()
                }
                
                Section("Simulator Settings") {
                    Toggle("Use Mock Visits", isOn: $useMockVisits)
                        .font(AppTheme.body)
                }
                
                Section("Account") {
                    Button("Logout") {
                        showLogoutAlert = true
                    }
                    .foregroundColor(.red)
                    .font(AppTheme.body)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    sessionManager.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var userEmail = "user@example.com"
    
    var body: some View {
        NavigationView {
            List {
                Section("Account Information") {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Email")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(userEmail)
                            .keelBodyMedium()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
                
                Section("App Information") {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Version")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("1.0.0")
                            .keelBodyMedium()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
                
                Section("Support") {
                    Button("Send Feedback") {
                        // Open feedback form
                    }
                    .font(AppTheme.body)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SessionManager.shared)
}
