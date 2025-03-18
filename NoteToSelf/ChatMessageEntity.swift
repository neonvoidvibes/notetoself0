import Foundation
import CoreData

@objc(ChatMessageEntity)
public class ChatMessageEntity: NSManagedObject {
}

extension ChatMessageEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessageEntity> {
        return NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var role: String?
    @NSManaged public var timestamp: Date?
}