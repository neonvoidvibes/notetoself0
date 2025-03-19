import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    
    // Marks when user started this session, for clearing conversation
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
    
    // Load existing chat messages from Core Data, only from this session onward
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
    
    // MARK: - Journal filter structure
    
    /// Basic timeframe filter for future expansions (mood filters, text search, etc.)
    enum JournalTimeframe {
        case all
        case since(Date)
        case dateRange(Date, Date)
    }
    
    struct JournalFilter {
        var timeframe: JournalTimeframe
        // Could add more, e.g. moods: [String], textSearch, etc.
    }
    
    /// Fetches journal entries from Core Data based on a filter.
    private func fetchJournalEntries(with filter: JournalFilter) throws -> [JournalEntryEntity] {
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        
        // Setup sort
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        // Setup predicate based on timeframe
        switch filter.timeframe {
        case .all:
            request.predicate = nil // no time limit
        case let .since(date):
            request.predicate = NSPredicate(format: "timestamp >= %@", date as NSDate)
        case let .dateRange(start, end):
            request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", start as NSDate, end as NSDate)
        }
        
        // For a v1, we won't do limit unless user specifically asks
        // request.fetchLimit = ...
        
        // Execute fetch
        return try context.fetch(request)
    }
    
    /// Convert an array of JournalEntryEntity into a text block for GPT usage
    private func buildJournalEntriesText(_ entries: [JournalEntryEntity]) -> String {
        if entries.isEmpty {
            return "No journal entries found."
        }
        let lines = entries.map { entry -> String in
            let dateStr = entry.timestamp?.formatted(date: .numeric, time: .omitted) ?? "Unknown date"
            let moodStr = entry.mood ?? "N/A"
            let textStr = entry.text ?? ""
            return "[\(dateStr)] (\(moodStr)) \(textStr)"
        }
        return lines.joined(separator: "\n")
    }
    
    /// Called when user taps 'Send'
    func sendMessage(_ userText: String) {
        Swift.print("📝 [ChatVM] Received user message: \(userText)")
        
        // We'll store the user text exactly as typed, so the user sees it in the chat bubble
        // BUT we'll keep *hidden* the journal text portion from the user’s bubble
        let normalized = userText.lowercased()
        
        // Check if user wants their journal entries included
        var hiddenJournalText: String? = nil
        if normalized.contains("journal entries") || normalized.contains("my journal") {
            do {
                // For v1, we fetch "all" unless we add more logic
                let entries = try fetchJournalEntries(with: JournalFilter(timeframe: .all))
                let textBlock = buildJournalEntriesText(entries)
                hiddenJournalText = textBlock
            } catch {
                Swift.print("❌ [ChatVM] Error fetching journal entries: \(error.localizedDescription)")
                hiddenJournalText = "Error reading journal entries."
            }
        }
        
        // Step 1: Save user’s local ChatMessage
        // The user’s message content is exactly what they typed—no appended journal data
        isAssistantTyping = true
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText // only the user text
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        Swift.print("💾 [ChatVM] Saved user message locally. Total messages: \(messages.count)")
        
        // Step 2: Build conversation context for GPT
        // If hiddenJournalText != nil, we’ll add it as “system” or “assistant” in the prompt
        // so GPT sees that info but the user does not see it appended in the UI
        let chatHistoryContext = buildChatContext(for: messages, hiddenJournal: hiddenJournalText)
        Swift.print("📜 [ChatVM] Sending conversation context:\n\(chatHistoryContext)")
        
        // Step 3: Call GPT-4o asynchronously
        Task {
            do {
                Swift.print("🤖 [ChatVM] Sending conversation context to GPT-4o...")
                let reply = try await chatService.sendMessage(
                    systemPrompt: SystemPrompts.defaultPrompt,
                    userMessage: chatHistoryContext
                )
                Swift.print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                
                // Step 4: Create assistant’s local ChatMessage
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                Swift.print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
                isAssistantTyping = false
            } catch {
                Swift.print("❌ [ChatVM] Error calling GPT-4o: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    /// Builds the final text that we send to GPT, incorporating the existing conversation
    /// plus any hidden journal text (system-level info) if needed.
    private func buildChatContext(for existingMessages: [ChatMessageEntity],
                                  hiddenJournal: String?) -> String {
        /*
         We’ll map each ChatMessageEntity to lines: “User: …” or “Assistant: …”
         Then, if hiddenJournal != nil, we insert it as a “System: …” line
         so GPT can see the user’s hidden context, but the user does not see it appended.
        */
        var lines: [String] = []
        
        for msg in existingMessages {
            let roleLabel = (msg.role ?? "user").capitalized
            let content = msg.content ?? ""
            lines.append("\(roleLabel): \(content)")
        }
        
        if let hiddenText = hiddenJournal {
            // If we want GPT to treat it as system context:
            lines.append("System: The user also has these journal entries:\n\(hiddenText)")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ChatVM] Context saved successfully")
        } catch {
            Swift.print("❌ [ChatVM] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    /// Called on initial load if no messages exist yet
    func sendInitialHiddenMessage() {
        Task {
            isAssistantTyping = true
            do {
                let reply = try await chatService.sendMessage(
                    systemPrompt: SystemPrompts.defaultPrompt,
                    userMessage: "init"
                )
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
