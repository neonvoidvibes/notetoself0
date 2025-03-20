import Foundation
import SwiftUI
import CoreData

@MainActor
final class ReflectionsViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    @Published var isUserStopping: Bool = false
    @Published var messages: [ChatMessageEntity] = []

    private let context = PersistenceController.shared.container.viewContext
    private let reflectionService = GPT4ReflectionsService.shared
    
    private let reflectionAgentSystemPrompt: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return SystemPrompts.basePrompt + "\n\n" + SystemPrompts.chatAgentPrompt + "\n\nAssume today's date is \(today)."
    }()
    
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
        if !Calendar.current.isDate(sessionStart, equalTo: Date(), toGranularity: .day) {
            Swift.print("New day detected. Clearing conversation.")
            clearConversation()
        }
        if messages.isEmpty {
            Swift.print("💬 [ReflectionsVM] No messages found, sending initial hidden message.")
            sendInitialHiddenMessage()
        } else {
            Swift.print("✅ [ReflectionsVM] Loaded \(messages.count) messages.")
        }
    }
    
    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
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
                
                let assistantEntry = ChatMessageEntity(context: context)
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
    
    func sendMessage(_ userText: String) {
        Swift.print("📝 [ReflectionsVM] Received user message: \(userText)")
        
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        proceedWithChat(userText, hiddenJournal: nil)
    }
    
    private func parseAssistantReply(_ text: String) -> (shouldRetrieve: Bool, query: String?) {
        if let jsonStart = text.firstIndex(of: "{"),
           let jsonEnd = text.lastIndex(of: "}"),
           jsonEnd > jsonStart {
            let jsonString = String(text[jsonStart...jsonEnd])
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let parsed = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any]
                    if let action = parsed?["action"] as? String,
                       action.lowercased() == "retrieve",
                       let q = parsed?["query"] as? String {
                        return (true, q)
                    }
                } catch {}
            }
        }
        return (false, nil)
    }
    
    private func proceedWithChat(_ userMessage: String, hiddenJournal: String?) {
        isAssistantTyping = true
        let chatHistoryContext = buildChatContext(for: messages, hiddenJournal: hiddenJournal)
        Swift.print("📜 [ReflectionsVM] Sending context to GPT-4:")
        
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
                
                let (shouldRetrieve, retrievalQuery) = parseAssistantReply(reply)
                if shouldRetrieve, let query = retrievalQuery {
                    let confirmation = "Please hold on a moment while I retrieve your data."
                    let assistantEntry = ChatMessageEntity(context: context)
                    assistantEntry.id = UUID()
                    assistantEntry.content = confirmation
                    assistantEntry.role = "assistant"
                    assistantEntry.timestamp = Date()
                    saveContext()
                    messages.append(assistantEntry)
                    Swift.print("💾 [ReflectionsVM] Saved confirmation message. Total messages: \(messages.count)")
                    handOffToJournalRetrieval(query: query)
                } else {
                    let assistantEntry = ChatMessageEntity(context: context)
                    assistantEntry.id = UUID()
                    assistantEntry.content = reply
                    assistantEntry.role = "assistant"
                    assistantEntry.timestamp = Date()
                    saveContext()
                    messages.append(assistantEntry)
                    Swift.print("💾 [ReflectionsVM] Saved assistant message. Total messages: \(messages.count)")
                }
                isAssistantTyping = false
                
            } catch {
                Swift.print("❌ [ReflectionsVM] GPT-4 error: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    private func buildChatContext(for existingMessages: [ChatMessageEntity], hiddenJournal: String?) -> String {
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
    
    private func handOffToJournalRetrieval(query: String) {
        guard !isUserStopping else { return }
        Swift.print("🔎 [ReflectionsVM] Handing off to JournalRetrievalAgent with query: \(query)")
        
        isAssistantTyping = true
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                if isUserStopping {
                    Swift.print("🛑 [ReflectionsVM] User stopped retrieval mid-task.")
                    isAssistantTyping = false
                    isUserStopping = false
                    return
                }
                
                let fetchedData = JournalRetrievalAgent(context: context).fetchJournalData(query: query)
                Swift.print("🔎 [ReflectionsVM] Journal data fetched, length: \(fetchedData.count)")
                
                isAssistantTyping = false
                proceedWithChat(query, hiddenJournal: fetchedData)
                
            } catch {
                Swift.print("❌ [ReflectionsVM] Retrieval agent error: \(error)")
                isAssistantTyping = false
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ReflectionsVM] Context saved successfully")
        } catch {
            Swift.print("❌ [ReflectionsVM] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func userStop() {
        Swift.print("🛑 [ReflectionsVM] userStop invoked.")
        isUserStopping = true
        isAssistantTyping = false
    }
    
    func resetStopState() {
        isUserStopping = false
    }
    
    func clearConversation() {
        sessionStart = Date()
        messages.removeAll()
        loadMessages()
        if messages.isEmpty {
            sendInitialHiddenMessage()
        }
    }
}