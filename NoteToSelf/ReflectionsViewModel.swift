import Foundation
import SwiftUI
import CoreData

@MainActor
final class ReflectionsViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    @Published var isUserStopping: Bool = false
    @Published var messages: [ReflectionMessageEntity] = []
    
    // daily free usage gating
    private var dailyFreeMessageCount: Int = 0
    private let maxFreeMessagesPerDay: Int = 3
    
    private let context = PersistenceController.shared.container.viewContext
    private let reflectionService = GPT4ReflectionsService.shared
    
    // We'll repurpose sessionStart to track daily usage resets
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
    
    init() {
        Swift.print("🚀 [ReflectionsVM] Initializing ReflectionsViewModel...")
        loadMessages()
        resetDailyCountIfNewDay()
        if messages.isEmpty {
            Swift.print("💬 [ReflectionsVM] No messages found, sending initial hidden message.")
            sendInitialHiddenMessage()
        } else {
            Swift.print("✅ [ReflectionsVM] Loaded \(messages.count) messages.")
        }
    }
    
    private func resetDailyCountIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(sessionStart, inSameDayAs: today) {
            dailyFreeMessageCount = 0
            sessionStart = today
        }
    }
    
    func canSendMessage() -> Bool {
        resetDailyCountIfNewDay()
        
        // check subscription from manager
        if SubscriptionManager.shared.isUserSubscribed {
            return true
        }
        
        return dailyFreeMessageCount < maxFreeMessagesPerDay
    }
    
    func sendMessage(_ userText: String) {
        Swift.print("📝 [ReflectionsVM] Received user message: \(userText)")
        
        guard canSendMessage() else {
            Swift.print("❌ [ReflectionsVM] User reached daily free limit.")
            return
        }
        dailyFreeMessageCount += 1
        
        let userEntry = ReflectionMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        proceedWithChat(userText, hiddenJournal: nil)
    }
    
    private func loadMessages() {
        let request = NSFetchRequest<ReflectionMessageEntity>(entityName: "ReflectionMessageEntity")
        request.predicate = NSPredicate(format: "timestamp >= %@", sessionStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            messages = try context.fetch(request)
            Swift.print("✅ [ReflectionsVM] Loaded \(messages.count) messages.")
        } catch {
            Swift.print("❌ [ReflectionsVM] Failed to load messages: \(error.localizedDescription)")
        }
    }
    
    private func sendInitialHiddenMessage() {
        isAssistantTyping = true
        Task {
            do {
                let reply = try await reflectionService.sendMessage(
                    systemPrompt: reflectionAgentSystemPrompt,
                    userMessage: "init"
                )
                Swift.print("🤖 [ReflectionsVM] Received initial assistant reply: \(reply)")
                
                let assistantEntry = ReflectionMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                isAssistantTyping = false
            } catch {
                Swift.print("❌ [ReflectionsVM] Error sending initial message: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    func userStop() {
        Swift.print("🛑 [ReflectionsVM] userStop invoked.")
        isUserStopping = true
        isAssistantTyping = false
    }
    
    func clearConversation() {
        // Clear all reflection messages from DB
        for msg in messages {
            context.delete(msg)
        }
        saveContext()
        messages.removeAll()
        // Re-init session start
        sessionStart = Date()
        dailyFreeMessageCount = 0
        sendInitialHiddenMessage()
    }
    
    private func proceedWithChat(_ userMessage: String, hiddenJournal: String?) {
        isAssistantTyping = true
        let chatHistoryContext = buildChatContext(for: messages, hiddenJournal: hiddenJournal)
        
        Task {
            do {
                let reply = try await reflectionService.sendMessage(
                    systemPrompt: reflectionAgentSystemPrompt,
                    userMessage: chatHistoryContext
                )
                if isUserStopping {
                    Swift.print("🛑 [ReflectionsVM] Stopped after request returned.")
                    isAssistantTyping = false
                    isUserStopping = false
                    return
                }
                Swift.print("🤖 [ReflectionsVM] Received GPT-4 reply: \(reply)")
                
                let assistantEntry = ReflectionMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                isAssistantTyping = false
                
            } catch {
                Swift.print("❌ [ReflectionsVM] GPT-4 error: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    private func buildChatContext(for existingMessages: [ReflectionMessageEntity], hiddenJournal: String?) -> String {
        var lines: [String] = []
        for msg in existingMessages {
            let roleLabel = (msg.role ?? "user").capitalized
            let content = msg.content ?? ""
            lines.append("\(roleLabel): \(content)")
        }
        if let hidden = hiddenJournal {
            lines.append("System: The user also has these journal entries:\n\(hidden)")
        }
        return lines.joined(separator: "\n")
    }
    
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ReflectionsVM] Context saved successfully")
        } catch {
            Swift.print("❌ [ReflectionsVM] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private var reflectionAgentSystemPrompt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return SystemPrompts.basePrompt + "\n\n" + SystemPrompts.chatAgentPrompt + "\n\nAssume today's date is \(today)."
    }
}