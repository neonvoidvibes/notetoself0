import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessageEntity] = []
    private let context = PersistenceController.shared.container.viewContext
    private let chatService = GPT4ChatService.shared

    init() {
        loadMessages()
    }

    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
        } catch {
            print("Error fetching chat messages: \(error)")
        }
    }

    func sendMessage(_ userMessage: String) {
        // Save user message
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userMessage
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        // Call GPT-4o and save assistant reply
        Task {
            do {
                let reply = try await chatService.sendMessage(systemPrompt: SystemPrompts.defaultPrompt, userMessage: userMessage)
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
            } catch {
                print("Error calling GPT-4o: \(error)")
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}