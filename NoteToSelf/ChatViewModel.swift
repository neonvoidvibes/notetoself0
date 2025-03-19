import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false

    private var sessionStart: Date {
        get {
            if let stored = UserDefaults.standard.object(forKey: "ChatSessionStart") as? Date {
                return stored
            }
            let now = Date()
            UserDefaults.standard.set(now, forKey: "ChatSessionStart")
            return now
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ChatSessionStart")
        }
    }
    
    @Published var messages: [ChatMessageEntity] = []
    private let context = PersistenceController.shared.container.viewContext
    private let chatService = GPT4ChatService.shared

    init() {
        Swift.print("🚀 [ChatVM] Initializing ChatViewModel...")
        loadMessages()
    }
    
    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.predicate = NSPredicate(format: "timestamp >= %@", sessionStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
            Swift.print("✅ [ChatVM] Loaded \(messages.count) messages from Core Data (since sessionStart)")
            if messages.isEmpty {
                Swift.print("💬 [ChatVM] No messages found, sending hidden user message to prompt assistant.")
                sendInitialHiddenMessage()
            }
        } catch {
            Swift.print("❌ [ChatVM] Failed to load messages: \(error.localizedDescription)")
        }
    }
    
    // Helper: fetch most recent journal entries (limit default to 3)
    private func fetchLatestEntries(limit: Int = 3) -> String {
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        do {
            let results = try context.fetch(request)
            if results.isEmpty {
                return "No journal entries found."
            } else {
                let lines = results.map { entry -> String in
                    let dateStr = entry.timestamp?.formatted(date: .numeric, time: .omitted) ?? "Unknown date"
                    let moodStr = entry.mood ?? "N/A"
                    let textStr = entry.text ?? ""
                    return "[\(dateStr)] (\(moodStr)) \(textStr)"
                }
                return lines.joined(separator: "\n")
            }
        } catch {
            Swift.print("❌ [ChatVM] Error fetching journal entries: \(error.localizedDescription)")
            return "Error reading journal entries."
        }
    }
    
    func sendMessage(_ userMessage: String) {
        Swift.print("📝 [ChatVM] Received user message: \(userMessage)")
        
        var finalUserMessage = userMessage
        let normalized = userMessage.lowercased()
        if normalized.contains("journal entries") || normalized.contains("my journal") {
            let entriesText = fetchLatestEntries()
            finalUserMessage += "\n\n[User's recent journal entries]\n\(entriesText)"
        }
        
        isAssistantTyping = true
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = finalUserMessage
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        Swift.print("💾 [ChatVM] Saved user message locally. Total messages: \(messages.count)")
        
        let conversationContext = messages.map { message -> String in
            let roleLabel = (message.role ?? "User").capitalized
            return "\(roleLabel): \(message.content ?? "")"
        }.joined(separator: "\n")
        Swift.print("📜 [ChatVM] Sending conversation context:\n\(conversationContext)")
        
        Task {
            do {
                Swift.print("🤖 [ChatVM] Sending conversation context to GPT-4o...")
                let reply = try await chatService.sendMessage(systemPrompt: SystemPrompts.defaultPrompt, userMessage: conversationContext)
                Swift.print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                Swift.print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
                isAssistantTyping = false
            } catch let serviceErr {
                Swift.print("❌ [ChatVM] Error calling GPT-4o: \(serviceErr.localizedDescription)")
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ChatVM] Context saved successfully")
        } catch let saveErr {
            Swift.print("❌ [ChatVM] Failed to save context: \(saveErr.localizedDescription)")
        }
    }
    
    func sendInitialHiddenMessage() {
        Task {
            isAssistantTyping = true
            do {
                let reply = try await chatService.sendMessage(systemPrompt: SystemPrompts.defaultPrompt, userMessage: "init")
                Swift.print("🤖 [ChatVM] Received initial assistant reply: \(reply)")
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                Swift.print("💾 [ChatVM] Saved initial assistant message locally. Total messages: \(messages.count)")
                isAssistantTyping = false
            } catch {
                Swift.print("❌ [ChatVM] Error sending initial hidden message: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    func clearConversation() {
        sessionStart = Date()
        messages.removeAll()
        loadMessages()
    }
}