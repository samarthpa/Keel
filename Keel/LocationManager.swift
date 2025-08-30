// ⚠️ Don't forget to enable Background Modes > Location Updates in Xcode Signing & Capabilities.

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    let api = ApiClient()
    let visitStore = VisitStore()
    
    @Published var events: [String] = []
    
    // Track visits for dwell time calculation
    private var visitStartTimes: [String: Date] = [:]
    private var merchantVisitCounts: [String: Int] = [:]
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermissions() {
        print("LocationManager: Requesting permissions...")
        
        // Check current authorization status first
        let currentStatus = locationManager.authorizationStatus
        print("LocationManager: Current authorization status: \(currentStatus.rawValue)")
        
        // Request "When In Use" authorization first
        print("LocationManager: Requesting 'When In Use' authorization...")
        locationManager.requestWhenInUseAuthorization()
        
        // Note: We'll request "Always" authorization after "When In Use" is granted
        // This is the recommended approach to avoid confusing the user
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        let event = "Visited \(visit.coordinate.latitude),\(visit.coordinate.longitude)"
        events.append(event)
        sendEventToServer(event)
        
        // Send notification for visit
        let notificationBody = "\(visit.coordinate.latitude),\(visit.coordinate.longitude)"
        NotificationManager.shared.send(title: "Arrived", body: notificationBody)
        
        // Save visit to Core Data
        let savedVisit = visitStore.saveVisit(
            lat: visit.coordinate.latitude,
            lon: visit.coordinate.longitude,
            arrival: visit.arrivalDate
        )
        
        // Track visit start time for dwell calculation
        let locationKey = "\(visit.coordinate.latitude),\(visit.coordinate.longitude)"
        visitStartTimes[locationKey] = visit.arrivalDate
        
        // Calculate confidence score
        let currentTime = Date()
        let dwellMinutes = (visitStartTimes[locationKey]?.timeIntervalSince(currentTime).magnitude ?? 0.0) / 60.0
        let priorVisits = merchantVisitCounts[locationKey] ?? 0
        let timeOfDay = Calendar.current.component(.hour, from: currentTime)
        
        let confidence = ConfidenceScorer.score(
            distanceMeters: nil, // We don't have distance from visit
            dwellMinutes: dwellMinutes,
            priorVisitsToMerchant: priorVisits,
            timeOfDay: timeOfDay
        )
        
        // Only proceed if confidence is high enough
        if confidence >= 0.6 {
            // Increment visit count for this location
            merchantVisitCounts[locationKey] = priorVisits + 1
            
            // Launch async task for merchant resolution and card scoring
            Task {
                do {
                    // Resolve merchant from coordinates
                    let merchantResponse = try await api.resolve(
                        lat: visit.coordinate.latitude, 
                        lon: visit.coordinate.longitude
                    )
                    
                    // Update visit with merchant info
                    await MainActor.run {
                        visitStore.updateVisitWithMerchant(visit: savedVisit, merchant: merchantResponse.merchant)
                    }
                    
                    // Create score request with temporary cards
                    let scoreRequest = ScoreRequest(
                        merchant: merchantResponse.merchant,
                        mcc: merchantResponse.mcc,
                        category: merchantResponse.category,
                        cards: ["Amex Gold", "Chase Freedom", "Citi Custom Cash"]
                    )
                    
                    // Get card recommendations
                    let scoreResponse = try await api.score(req: scoreRequest)
                    
                    // Add best card recommendation to events
                    let bestCard = scoreResponse.top.first?.card ?? "None"
                    let reason = scoreResponse.top.first?.reason ?? ""
                    let cardEvent = "Best card: \(bestCard) — \(reason)"
                    await MainActor.run {
                        events.append(cardEvent)
                        // Update visit with recommendation
                        visitStore.updateVisitWithRecommendation(visit: savedVisit, recommendedCard: bestCard)
                    }
                    
                    // Send notification with best card
                    NotificationManager.shared.send(
                        title: "Best card here", 
                        body: "\(bestCard): \(reason)"
                    )
                    
                } catch {
                    // Handle errors
                    let errorEvent = "Error: \(error.localizedDescription)"
                    await MainActor.run {
                        events.append(errorEvent)
                    }
                }
            }
        } else {
            // Low confidence - wait for more dwell time
            let lowConfidenceEvent = "Low confidence (\(String(format: "%.2f", confidence))); waiting for dwell"
            events.append(lowConfidenceEvent)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let event = "Moved to \(location.coordinate.latitude),\(location.coordinate.longitude)"
        events.append(event)
        sendEventToServer(event)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LocationManager: Authorization status changed to: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse:
            print("LocationManager: 'When In Use' authorization granted")
            // Now request "Always" authorization for background monitoring
            print("LocationManager: Requesting 'Always' authorization for background monitoring...")
            locationManager.requestAlwaysAuthorization()
            
        case .authorizedAlways:
            print("LocationManager: 'Always' authorization granted - starting location monitoring")
            // Start monitoring for significant location changes and visits
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startMonitoringVisits()
            
        case .denied, .restricted:
            print("LocationManager: Authorization denied or restricted")
            
        case .notDetermined:
            print("LocationManager: Authorization not determined")
            
        @unknown default:
            print("LocationManager: Unknown authorization status")
        }
    }
    
    // MARK: - Server Communication
    
    private func sendEventToServer(_ event: String) {
        guard let url = URL(string: "https://example.com/api/location-event") else {
            print("Invalid URL")
            return
        }
        
        // Create JSON body
        let jsonBody = ["event": event]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Event sent successfully: \(event)")
                    } else {
                        print("Request failed with status code: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
            
        } catch {
            print("Failed to create JSON data: \(error.localizedDescription)")
        }
    }
}
