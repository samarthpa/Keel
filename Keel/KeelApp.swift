import SwiftUI

@main
struct KeelApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(SessionManager.shared)
        }
    }
}
