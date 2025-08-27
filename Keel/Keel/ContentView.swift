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
                Text("Recent Visits")
                    .font(.largeTitle)
                    .padding()
                
                List {
                    ForEach(visits) { visit in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(visit.merchant ?? "Unknown Location")
                                    .font(.headline)
                                Spacer()
                                Text(visit.arrival, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let card = visit.recommendedCard {
                                Text("💳 \(card)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("📍 \(String(format: "%.4f", visit.lat)), \(String(format: "%.4f", visit.lon))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Button("Request Permissions") {
                    locationManager.requestPermissions()
                }
                .padding()
            }
            .navigationTitle("Keel")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
