import Foundation
import CoreData

extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create some sample JournalEntryEntity data for SwiftUI previews
        for i in 0..<3 {
            let sample = JournalEntryEntity(context: viewContext)
            sample.timestamp = Date().addingTimeInterval(Double(i) * -86400)
            sample.text = "Sample text #\(i)"
            sample.mood = ["Happy", "Neutral", "Sad"].randomElement()!
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save preview context: \\(error)")
        }
        
        return controller
    }()
}