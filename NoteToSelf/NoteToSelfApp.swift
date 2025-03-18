import SwiftUI
import CoreData

@main
struct NoteToSelfApp: App {
    // Shared Core Data persistence
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}