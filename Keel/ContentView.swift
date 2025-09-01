import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Visit.arrival, ascending: false)],
        animation: .default)
    private var visits: FetchedResults<Visit>
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with branding
                VStack(spacing: 16) {
                    Text("Keel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("The smarter way to use your credit cards.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                
                // Recent Visits Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recent Visits")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    if visits.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No visits yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("Enable location permissions to start tracking your visits")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    } else {
                        List {
                            ForEach(visits) { visit in
                                VisitCard(visit: visit)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                Spacer()
                
                // Action Button
                Button("Request Permissions") {
                    print("Request Permissions button tapped")
                    locationManager.requestPermissions()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Visit Card Component

struct VisitCard: View {
    let visit: Visit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Merchant and Time
            HStack {
                Text(visit.merchant ?? "Unknown Location")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(visit.arrival ?? Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Recommended Card
            if let card = visit.recommendedCard {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text(card)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Location Coordinates
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.4f", visit.lat)), \(String(format: "%.4f", visit.lon))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
