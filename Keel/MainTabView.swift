import SwiftUI
import MapKit

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
            
            // Map Tab
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(5)
        }
        .accentColor(AppTheme.primaryGreen)
        .environmentObject(sessionManager)
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var userCardStore = UserCardStore.shared
    @State private var lastRecommendation: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLocationPicker = false
    @State private var selectedLocation: LocationOption?
    @State private var lastVisitData: VisitData?
    
    // Predefined locations for testing
    private let testLocations: [LocationOption] = [
        LocationOption(name: "Starbucks - Downtown", lat: 37.7749, lon: -122.4194, description: "Coffee shop in San Francisco"),
        LocationOption(name: "Target - Shopping Center", lat: 37.7849, lon: -122.4094, description: "Department store"),
        LocationOption(name: "Shell Gas Station", lat: 37.7649, lon: -122.4294, description: "Gas station"),
        LocationOption(name: "Whole Foods Market", lat: 37.7549, lon: -122.4394, description: "Grocery store"),
        LocationOption(name: "McDonald's", lat: 37.7449, lon: -122.4494, description: "Fast food restaurant"),
        LocationOption(name: "Walmart Supercenter", lat: 37.7349, lon: -122.4594, description: "Big box retailer"),
        LocationOption(name: "CVS Pharmacy", lat: 37.7249, lon: -122.4694, description: "Pharmacy"),
        LocationOption(name: "Home Depot", lat: 37.7149, lon: -122.4794, description: "Home improvement store")
    ]
    
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
                        
                        // Card Status Indicator
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(AppTheme.primaryGreen)
                            Text("\(userCardStore.getActiveCards().count) active cards")
                                .keelCaption()
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.spacingM)
                        .padding(.vertical, AppTheme.spacingS)
                        .background(AppTheme.primaryGreen.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.top, AppTheme.spacingL)
                    
                    // Last Visit Card
                    if let visitData = lastVisitData {
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Last Visit")
                                .keelTitleSmall()
                                .foregroundColor(AppTheme.textPrimary)
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                                HStack {
                                    Text(visitData.merchant)
                                        .keelBodyMedium()
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("\(Int(visitData.confidence * 100))%")
                                        .keelCaption()
                                        .foregroundColor(AppTheme.primaryGreen)
                                }
                                
                                if let category = visitData.category {
                                    Text("Category: \(category)")
                                        .keelCaption()
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                if let topCard = visitData.topCard {
                                    HStack {
                                        Text("Best Card:")
                                            .keelBody()
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        Text(topCard)
                                            .keelBody()
                                            .foregroundColor(AppTheme.primaryGreen)
                                            .fontWeight(.medium)
                                    }
                                }
                                
                                if let reason = visitData.reason {
                                    Text("Reason: \(reason)")
                                        .keelCaption()
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        .padding(.horizontal, AppTheme.spacingL)
                    }
                    
                    // Action Buttons
                    VStack(spacing: AppTheme.spacingM) {
                        Button("Simulate Visit to Real Store") {
                            showLocationPicker = true
                        }
                        .keelPrimaryButton()
                        .disabled(isLoading)
                        
                        if let selectedLocation = selectedLocation {
                            Button("Visit \(selectedLocation.name)") {
                                simulateVisitToLocation(selectedLocation)
                            }
                            .keelSecondaryButton()
                            .disabled(isLoading)
                        }
                        
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
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    locations: testLocations,
                    selectedLocation: $selectedLocation,
                    isPresented: $showLocationPicker
                )
            }
        }
    }
    
    private func simulateVisit() {
        // Legacy function - now calls the new location-based simulation
        let defaultLocation = LocationOption(name: "Default Location", lat: 37.7749, lon: -122.4194, description: "San Francisco")
        simulateVisitToLocation(defaultLocation)
    }
    
    private func simulateVisitToLocation(_ location: LocationOption) {
        isLoading = true
        
        // Call the backend mock visit endpoint with user's active cards
        let apiClient = ApiClient.shared
        let activeCards = userCardStore.getActiveCards()
        let request = MockVisitRequest(
            lat: location.lat, 
            lon: location.lon, 
            user_cards: activeCards.isEmpty ? nil : activeCards
        )
        
        apiClient.mockVisit(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { response in
                    // Parse the response and update the UI
                    let visitData = VisitData(
                        merchant: response.merchant,
                        category: response.category,
                        confidence: response.confidence,
                        topCard: response.top_card,
                        reason: response.reason,
                        requestId: response.request_id
                    )
                    lastVisitData = visitData
                }
            )
            .store(in: &apiClient.cancellables)
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
    @ObservedObject private var userCardStore = UserCardStore.shared
    @StateObject private var availableCardStore = AvailableCardStore()
    @State private var showingAddCard = false
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0 = My Cards, 1 = Add Cards
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("My Cards").tag(0)
                    Text("Add Cards").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    myCardsView
                } else {
                    addCardsView
                }
            }
            .navigationTitle("Cards")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddCard) {
                AddCardView(userCardStore: userCardStore)
            }
        }
    }
    
    private var myCardsView: some View {
        Group {
            if userCardStore.userCards.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "No Cards Yet",
                    message: "No cards added yet",
                    ctaTitle: "Add Your First Card",
                    ctaAction: { showingAddCard = true }
                )
            } else {
                List {
                    ForEach(userCardStore.userCards) { card in
                        CardRowView(card: card, userCardStore: userCardStore)
                    }
                    .onDelete(perform: deleteCards)
                }
            }
        }
    }
    
    private var addCardsView: some View {
        VStack {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            // Available Cards List
            List {
                ForEach(filteredAvailableCards, id: \.name) { availableCard in
                    AvailableCardRowView(
                        availableCard: availableCard,
                        userCardStore: userCardStore
                    )
                }
            }
        }
    }
    
    private var filteredAvailableCards: [AvailableCard] {
        let filtered = availableCardStore.searchCards(searchText)
        return filtered.filter { availableCard in
            !userCardStore.userCards.contains { $0.name == availableCard.name }
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        for index in offsets {
            let card = userCardStore.userCards[index]
            userCardStore.removeCard(card)
        }
    }
}

// MARK: - Card Row View
struct CardRowView: View {
    let card: UserCard
    let userCardStore: UserCardStore
    
    var body: some View {
        HStack {
            // Card Icon
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(AppTheme.primaryGreen)
                .frame(width: 40, height: 25)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(card.name)
                    .keelBodyMedium()
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack {
                    Text(card.isActive ? "Active" : "Inactive")
                        .keelCaption()
                        .foregroundColor(card.isActive ? AppTheme.primaryGreen : AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Added \(card.addedDate, style: .date)")
                        .keelCaption()
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { card.isActive },
                set: { _ in userCardStore.toggleCard(card) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, AppTheme.spacingXS)
    }
}

// MARK: - Available Card Row View
struct AvailableCardRowView: View {
    let availableCard: AvailableCard
    let userCardStore: UserCardStore
    
    var body: some View {
        HStack {
            // Card Icon
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(AppTheme.primaryGreen)
                .frame(width: 40, height: 25)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(availableCard.name)
                    .keelBodyMedium()
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(availableCard.description)
                    .keelCaption()
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(availableCard.category)
                    .keelCaption()
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(.horizontal, AppTheme.spacingXS)
                    .padding(.vertical, 2)
                    .background(AppTheme.primaryGreen.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button("Add") {
                userCardStore.addCard(availableCard.name)
            }
            .keelSecondaryButton()
        }
        .padding(.vertical, AppTheme.spacingXS)
    }
}

// MARK: - Add Card View
struct AddCardView: View {
    @ObservedObject var userCardStore: UserCardStore
    @Environment(\.presentationMode) var presentationMode
    @State private var cardName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacingL) {
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("Card Name")
                        .keelBodyMedium()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    TextField("Enter card name", text: $cardName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(AppTheme.body)
                }
                
                Spacer()
                
                Button("Add Card") {
                    if !cardName.isEmpty {
                        userCardStore.addCard(cardName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .keelPrimaryButton()
                .disabled(cardName.isEmpty)
            }
            .padding()
            .navigationTitle("Add Custom Card")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textSecondary)
            
            TextField("Search cards...", text: $text)
                .font(AppTheme.body)
        }
        .padding(AppTheme.spacingS)
        .background(AppTheme.surface)
        .cornerRadius(8)
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

// MARK: - Supporting Data Structures

struct LocationOption: Identifiable {
    let id = UUID()
    let name: String
    let lat: Double
    let lon: Double
    let description: String
}

struct VisitData {
    let merchant: String
    let category: String?
    let confidence: Double
    let topCard: String?
    let reason: String?
    let requestId: String
}



// MARK: - Location Picker View

struct LocationPickerView: View {
    let locations: [LocationOption]
    @Binding var selectedLocation: LocationOption?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List(locations) { location in
                Button(action: {
                    selectedLocation = location
                    isPresented = false
                }) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text(location.name)
                            .keelBodyMedium()
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(location.description)
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("📍 \(String(format: "%.4f", location.lat)), \(String(format: "%.4f", location.lon))")
                            .keelCaptionSmall()
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Map View
struct MapView: View {
    @ObservedObject private var userCardStore = UserCardStore.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var showingRecommendation = false
    @State private var recommendation: VisitData?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(AppTheme.primaryGreen)
                                .font(.title)
                                .background(Color.white)
                                .clipShape(Circle())
                            
                            if let recommendation = recommendation,
                               recommendation.merchant == annotation.title {
                                RecommendationBubble(recommendation: recommendation)
                            }
                        }
                    }
                }
                .onTapGesture { location in
                    handleMapTap(at: location)
                }
                
                // Loading overlay
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Finding best card...")
                            .keelBody()
                            .padding(.top, AppTheme.spacingS)
                    }
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(AppTheme.cornerRadiusM)
                    .shadow(radius: 4)
                }
                
                // Error banner
                if showError {
                    VStack {
                        Spacer()
                        ErrorBanner(
                            message: errorMessage,
                            onDismiss: { showError = false }
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle("Card Map")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("My Location") {
                        centerOnUserLocation()
                    }
                }
            }
            .sheet(isPresented: $showingRecommendation) {
                if let recommendation = recommendation {
                    RecommendationDetailView(recommendation: recommendation)
                }
            }
        }
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        if let selectedLocation = selectedLocation {
            return [MapAnnotationItem(
                coordinate: selectedLocation,
                title: recommendation?.merchant ?? "Selected Location"
            )]
        }
        return []
    }
    
    private func handleMapTap(at location: CGPoint) {
        // For now, we'll use a simplified approach
        // In a real implementation, you'd convert screen coordinates to map coordinates
        // For demo purposes, we'll use the center of the current region
        let coordinate = region.center
        selectedLocation = coordinate
        getRecommendationForLocation(coordinate)
    }
    
    private func getRecommendationForLocation(_ coordinate: CLLocationCoordinate2D) {
        isLoading = true
        showError = false
        
        let apiClient = ApiClient.shared
        let activeCards = userCardStore.getActiveCards()
        let request = MockVisitRequest(
            lat: coordinate.latitude,
            lon: coordinate.longitude,
            user_cards: activeCards.isEmpty ? nil : activeCards
        )
        
        apiClient.mockVisit(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { response in
                    let visitData = VisitData(
                        merchant: response.merchant,
                        category: response.category,
                        confidence: response.confidence,
                        topCard: response.top_card,
                        reason: response.reason,
                        requestId: response.request_id
                    )
                    recommendation = visitData
                    showingRecommendation = true
                }
            )
            .store(in: &apiClient.cancellables)
    }
    
    private func centerOnUserLocation() {
        // For now, center on San Francisco
        // In a real app, you'd use CLLocationManager to get user's location
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

// MARK: - Map Annotation Item
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

// MARK: - Recommendation Bubble
struct RecommendationBubble: View {
    let recommendation: VisitData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(recommendation.merchant)
                .keelBodyMedium()
                .foregroundColor(AppTheme.textPrimary)
            
            Text(recommendation.topCard ?? "Unknown Card")
                .keelCaption()
                .foregroundColor(AppTheme.primaryGreen)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.surface)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// MARK: - Recommendation Detail View
struct RecommendationDetailView: View {
    let recommendation: VisitData
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacingL) {
                // Header
                VStack(spacing: AppTheme.spacingM) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryGreen)
                    
                    Text("Best Card Here")
                        .keelTitle()
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                // Recommendation Card
                VStack(spacing: AppTheme.spacingM) {
                    // Merchant Info
                    VStack(spacing: AppTheme.spacingS) {
                        Text(recommendation.merchant)
                            .keelHeadline()
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(recommendation.category ?? "Unknown Category")
                            .keelBody()
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Divider()
                    
                    // Card Recommendation
                    VStack(spacing: AppTheme.spacingS) {
                        Text("Recommended Card")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(recommendation.topCard ?? "Unknown Card")
                            .keelHeadline()
                            .foregroundColor(AppTheme.primaryGreen)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // Reason
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Why this card?")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(recommendation.reason ?? "No reason provided")
                            .keelBody()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    // Confidence
                    HStack {
                        Text("Confidence:")
                            .keelCaption()
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(recommendation.confidence * 100))%")
                            .keelCaption()
                            .foregroundColor(AppTheme.primaryGreen)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.cornerRadiusM)
                .shadow(radius: 2)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SessionManager.shared)
}
