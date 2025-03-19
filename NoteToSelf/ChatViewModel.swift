import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessageEntity] = []
    private let context = PersistenceController.shared.container.viewContext
    private let chatService = GPT4ChatService.shared

    init() {
        print("🚀 [ChatVM] Initializing ChatViewModel...")
        loadMessages()
    }

    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
            print("✅ [ChatVM] Loaded \(messages.count) messages from Core Data")
        } catch let fetchErr {
            print("❌ [ChatVM] Failed to load messages: \(fetchErr.localizedDescription)")
        }
    }

    func sendMessage(_ userMessage: String) {
        print("📝 [ChatVM] Received user message: \(userMessage)")
        // Save user message
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userMessage
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        print("💾 [ChatVM] Saved user message locally. Total messages: \(messages.count)")

        // Construct conversation context from all messages
        let conversationContext = messages.map { message -> String in
            let roleLabel = (message.role ?? "User").capitalized
            return "\(roleLabel): \(message.content ?? "")"
        }.joined(separator: "\n")
        print("📜 [ChatVM] Sending conversation context:\n\(conversationContext)")

        // Call GPT-4o with full conversation history
        Task {
            do {
                print("🤖 [ChatVM] Sending conversation context to GPT-4o...")
                let reply = try await chatService.sendMessage(systemPrompt: SystemPrompts.defaultPrompt, userMessage: conversationContext)
                print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
            } catch let serviceErr {
                print("❌ [ChatVM] Error calling GPT-4o: \(serviceErr.localizedDescription)")
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
            print("💾 [ChatVM] Context saved successfully")
        } catch let saveErr {
            print("❌ [ChatVM] Failed to save context: \(saveErr.localizedDescription)")
        }
    }
}