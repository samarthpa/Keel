import Foundation
import CoreData

class VisitStore: ObservableObject {
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    func saveVisit(lat: Double, lon: Double, arrival: Date) -> Visit {
        let visit = Visit(context: viewContext)
        visit.id = UUID()
        visit.lat = lat
        visit.lon = lon
        visit.arrival = arrival
        visit.departure = nil
        visit.merchant = nil
        visit.recommendedCard = nil
        
        do {
            try viewContext.save()
            return visit
        } catch {
            print("Error saving visit: \(error)")
            fatalError("Core Data save error")
        }
    }
    
    func updateVisitWithMerchant(visit: Visit, merchant: String) {
        visit.merchant = merchant
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating visit with merchant: \(error)")
        }
    }
    
    func updateVisitWithRecommendation(visit: Visit, recommendedCard: String) {
        visit.recommendedCard = recommendedCard
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating visit with recommendation: \(error)")
        }
    }
    
    func fetchRecent(limit: Int = 10) -> [Visit] {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Visit.arrival, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching visits: \(error)")
            return []
        }
    }
    
    func findVisitByLocation(lat: Double, lon: Double, withinMinutes: Int = 5) -> Visit? {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Find visits within the time window and location tolerance
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(withinMinutes * 60))
        request.predicate = NSPredicate(format: "arrival >= %@ AND lat BETWEEN %@ AND %@ AND lon BETWEEN %@ AND %@",
                                      cutoffTime as NSDate,
                                      lat - 0.001 as NSNumber, lat + 0.001 as NSNumber,
                                      lon - 0.001 as NSNumber, lon + 0.001 as NSNumber)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Visit.arrival, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let visits = try viewContext.fetch(request)
            return visits.first
        } catch {
            print("Error finding visit by location: \(error)")
            return nil
        }
    }
}
