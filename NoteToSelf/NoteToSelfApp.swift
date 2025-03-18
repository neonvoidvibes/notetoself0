import SwiftUI
import CoreData

@main
struct NoteToSelfApp: App {
    // Shared Core Data persistence
    let persistenceController = PersistenceController.shared
    
    // Show onboarding only once
    @AppStorage("didCompleteOnboarding") var didCompleteOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if didCompleteOnboarding {
                MainJournalView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
