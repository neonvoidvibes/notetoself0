import CoreData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Attempt to load the model named "NoteToSelf" from the bundle
        guard let modelURL = Bundle.main.url(forResource: "NoteToSelf", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to locate or load the NoteToSelf model")
        }
        
        container = NSPersistentContainer(name: "NoteToSelf", managedObjectModel: managedObjectModel)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \\(error), \\(error.userInfo)")
            }
        }
    }
}
