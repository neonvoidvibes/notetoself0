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
        print("🚀 [ChatVM] Initializing ChatViewModel...")
        loadMessages()
    }

    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
            print("✅ [ChatVM] Loaded \(messages.count) messages from Core Data")
            print("✅ [ChatVM] Loaded \(messages.count) messages from Core Data")
            print("❌ [ChatVM] Failed to load messages: \(error.localizedDescription)")
            print("❌ [ChatVM] Failed to load messages: \(error.localizedDescription)")
        }
    }

    func sendMessage(_ userMessage: String) {
        print("📝 [ChatVM] Received user message: \(userMessage)")
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


        // Call GPT-4o and save assistant reply
        Task {
            do {
                print("🤖 [ChatVM] Sending message to GPT-4o...")
                print("🤖 [ChatVM] Sending message to GPT-4o...")
                print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                let reply = try await chatService.sendMessage(systemPrompt: SystemPrompts.defaultPrompt, userMessage: userMessage)
                print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
                print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
                print("❌ [ChatVM] Error calling GPT-4o: \(error.localizedDescription)")
                print("❌ [ChatVM] Error calling GPT-4o: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
            print("💾 [ChatVM] Context saved successfully")
            print("💾 [ChatVM] Context saved successfully")
            print("❌ [ChatVM] Failed to save context: \(error.localizedDescription)")
            print("❌ [ChatVM] Failed to save context: \(error.localizedDescription)")
        }
    }
}