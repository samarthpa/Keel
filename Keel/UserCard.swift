import Foundation
import SwiftUI

// MARK: - User Card Model

struct UserCard: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var isActive: Bool
    var addedDate: Date
    
    init(name: String, isActive: Bool = true) {
        self.name = name
        self.isActive = isActive
        self.addedDate = Date()
    }
}

// MARK: - User Card Store

class UserCardStore: ObservableObject {
    @Published var userCards: [UserCard] = []
    
    private let userDefaults = UserDefaults.standard
    private let cardsKey = "user_cards"
    
    // Singleton instance for shared access across views
    static let shared = UserCardStore()
    
    init() {
        loadCards()
    }
    
    // MARK: - Card Management
    
    func addCard(_ cardName: String) {
        // Check if card already exists
        if !userCards.contains(where: { $0.name.lowercased() == cardName.lowercased() }) {
            let newCard = UserCard(name: cardName)
            userCards.append(newCard)
            saveCards()
        }
    }
    
    func removeCard(_ card: UserCard) {
        userCards.removeAll { $0.id == card.id }
        saveCards()
    }
    
    func toggleCard(_ card: UserCard) {
        if let index = userCards.firstIndex(where: { $0.id == card.id }) {
            userCards[index].isActive.toggle()
            saveCards()
        }
    }
    
    func getActiveCards() -> [String] {
        return userCards.filter { $0.isActive }.map { $0.name }
    }
    
    func hasActiveCards() -> Bool {
        return !getActiveCards().isEmpty
    }
    
    // MARK: - Persistence
    
    private func saveCards() {
        if let encoded = try? JSONEncoder().encode(userCards) {
            userDefaults.set(encoded, forKey: cardsKey)
        }
    }
    
    private func loadCards() {
        if let data = userDefaults.data(forKey: cardsKey),
           let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
            userCards = decoded
        } else {
            // Load some default cards
            loadDefaultCards()
        }
    }
    
    private func loadDefaultCards() {
        let defaultCards = [
            "Chase Sapphire Preferred",
            "Amex Gold",
            "Citi Double Cash",
            "Chase Freedom Unlimited",
            "Capital One Venture",
            "Discover it Cash Back"
        ]
        
        userCards = defaultCards.map { UserCard(name: $0, isActive: true) }
        saveCards()
    }
}

// MARK: - Available Cards Data

struct AvailableCard {
    let name: String
    let category: String
    let description: String
    let benefits: [String]
}



// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

class AvailableCardStore: ObservableObject {
    @Published var availableCards: [AvailableCard] = []
    
    init() {
        loadAvailableCards()
    }
    
    private func loadAvailableCards() {
        availableCards = [
            AvailableCard(
                name: "Chase Sapphire Preferred",
                category: "Travel",
                description: "2x points on travel and dining",
                benefits: ["2x points on travel", "2x points on dining", "25% bonus on travel redemption"]
            ),
            AvailableCard(
                name: "Amex Gold",
                category: "Dining",
                description: "4x points on dining and groceries",
                benefits: ["4x points on dining", "4x points on groceries", "$120 dining credit"]
            ),
            AvailableCard(
                name: "Citi Double Cash",
                category: "General",
                description: "2% cash back on all purchases",
                benefits: ["2% cash back", "No annual fee", "No category restrictions"]
            ),
            AvailableCard(
                name: "Chase Freedom Unlimited",
                category: "General",
                description: "1.5% cash back on all purchases",
                benefits: ["1.5% cash back", "No annual fee", "Chase Ultimate Rewards"]
            ),
            AvailableCard(
                name: "Capital One Venture",
                category: "Travel",
                description: "2x miles on all purchases",
                benefits: ["2x miles on everything", "Global Entry credit", "No foreign transaction fees"]
            ),
            AvailableCard(
                name: "Discover it Cash Back",
                category: "Rotating",
                description: "5% cash back on rotating categories",
                benefits: ["5% rotating categories", "Cash back match", "No annual fee"]
            ),
            AvailableCard(
                name: "Wells Fargo Active Cash",
                category: "General",
                description: "2% cash back on all purchases",
                benefits: ["2% cash back", "No annual fee", "Cell phone protection"]
            ),
            AvailableCard(
                name: "Bank of America Customized Cash",
                category: "Flexible",
                description: "3% cash back in chosen category",
                benefits: ["3% in chosen category", "2% at grocery stores", "1% on everything else"]
            )
        ]
    }
    
    func searchCards(_ query: String) -> [AvailableCard] {
        if query.isEmpty {
            return availableCards
        }
        return availableCards.filter { 
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }
    
}
