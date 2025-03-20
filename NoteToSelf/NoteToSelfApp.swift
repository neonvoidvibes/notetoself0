import SwiftUI
import CoreData

@main
struct NoteToSelfApp: App {
    // Check if user has seen onboarding
    @AppStorage("HasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    // Shared Core Data persistence
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                // Show main interface
                MainTabbedView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                // Show multi-screen onboarding
                OnboardingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}