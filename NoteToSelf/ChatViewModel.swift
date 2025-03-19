import Foundation
import SwiftUI
import CoreData

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    @Published var isUserStopping: Bool = false
    @Published var messages: [ChatMessageEntity] = []

    private let context = PersistenceController.shared.container.viewContext
    private let chatService = GPT4ChatService.shared
    
    private let chatAgentSystemPrompt: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return SystemPrompts.basePrompt + "\n\n" + SystemPrompts.chatAgentPrompt + "\n\nAssume today's date is \(today)."
    }()
    
    /// The session start date, stored in UserDefaults so that clearing the conversation resets it.
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
    
    // MARK: - Init
    init() {
        Swift.print("🚀 [ChatVM] Initializing ChatViewModel...")
        loadMessages()
        if !Calendar.current.isDate(sessionStart, equalTo: Date(), toGranularity: .day) {
            Swift.print("New day detected. Clearing conversation.")
            clearConversation()
        }
        if messages.isEmpty {
            Swift.print("💬 [ChatVM] No messages found, sending initial hidden message.")
            sendInitialHiddenMessage()
        } else {
            Swift.print("✅ [ChatVM] Loaded \(messages.count) messages.")
        }
    }
    
    // MARK: - Load Messages
    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.predicate = NSPredicate(format: "timestamp >= %@", sessionStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            messages = try context.fetch(request)
            Swift.print("✅ [ChatVM] Loaded \(messages.count) messages.")
        } catch {
            Swift.print("❌ [ChatVM] Failed to load messages: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Send Initial Hidden Message
    private func sendInitialHiddenMessage() {
        isAssistantTyping = true
        Task {
            do {
                let reply = try await chatService.sendMessage(
                    systemPrompt: chatAgentSystemPrompt,
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
                isAssistantTyping = false
            } catch {
                Swift.print("❌ [ChatVM] Error sending initial message: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    // MARK: - User Action: Send Message
    func sendMessage(_ userText: String) {
        Swift.print("📝 [ChatVM] Received user message: \(userText)")
        
        // 1) Save user message
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        // 2) Proceed with normal chat. We'll parse the GPT-4 reply to see if retrieval is needed
        proceedWithChat(userText, hiddenJournal: nil)
    }
    
    // MARK: - Parse Assistant Reply for JSON
    private func parseAssistantReply(_ text: String) -> (shouldRetrieve: Bool, query: String?) {
        // Attempt to parse a JSON object of form {"action":"retrieve","query":"something"}
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
                } catch {
                    // It's not valid JSON or not the correct shape
                }
            }
        }
        return (false, nil)
    }
    
    // MARK: - Proceed with Chat
    private func proceedWithChat(_ userMessage: String, hiddenJournal: String?) {
        isAssistantTyping = true
        let chatHistoryContext = buildChatContext(for: messages, hiddenJournal: hiddenJournal)
        Swift.print("📜 [ChatVM] Sending context to GPT-4:")
        
        Task {
            do {
                let reply = try await chatService.sendMessage(
                    systemPrompt: chatAgentSystemPrompt,
                    userMessage: chatHistoryContext
                )
                if isUserStopping {
                    Swift.print("🛑 [ChatVM] Stopped after chat request returned.")
                    isAssistantTyping = false
                    isUserStopping = false
                    return
                }
                Swift.print("🤖 [ChatVM] Received GPT-4 reply: \(reply)")
                
                // Attempt to parse JSON for retrieval instructions
                let (shouldRetrieve, retrievalQuery) = parseAssistantReply(reply)
                
                if shouldRetrieve, let query = retrievalQuery {
                    // Instead of displaying the raw JSON, show a confirmation message
                    let confirmation = "Please hold on a moment while I retrieve your data."
                    let assistantEntry = ChatMessageEntity(context: context)
                    assistantEntry.id = UUID()
                    assistantEntry.content = confirmation
                    assistantEntry.role = "assistant"
                    assistantEntry.timestamp = Date()
                    saveContext()
                    messages.append(assistantEntry)
                    Swift.print("💾 [ChatVM] Saved confirmation message. Total messages: \(messages.count)")
                    handOffToJournalRetrieval(query: query)
                } else {
                    // Normal case: display the GPT-4 reply
                    let assistantEntry = ChatMessageEntity(context: context)
                    assistantEntry.id = UUID()
                    assistantEntry.content = reply
                    assistantEntry.role = "assistant"
                    assistantEntry.timestamp = Date()
                    saveContext()
                    messages.append(assistantEntry)
                    Swift.print("💾 [ChatVM] Saved assistant message. Total messages: \(messages.count)")
                }
                isAssistantTyping = false
                
            } catch {
                Swift.print("❌ [ChatVM] GPT-4 error: \(error.localizedDescription)")
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
    
    // MARK: - Hand off to Journal Retrieval
    private func handOffToJournalRetrieval(query: String) {
        guard !isUserStopping else { return }
        Swift.print("🔎 [ChatVM] Handing off to JournalRetrievalAgent with query: \(query)")
        
        // 1) show loading dot
        isAssistantTyping = true
        
        Task {
            do {
                // short delay to show "loading"
                try await Task.sleep(nanoseconds: 300_000_000)
                if isUserStopping {
                    Swift.print("🛑 [ChatVM] User stopped retrieval mid-task.")
                    isAssistantTyping = false
                    isUserStopping = false
                    return
                }
                
                // 2) Actually fetch data
                let fetchedData = JournalRetrievalAgent(context: context).fetchJournalData(query: query)
                Swift.print("🔎 [ChatVM] Journal data fetched, length: \(fetchedData.count)")
                
                isAssistantTyping = false
                // 3) Provide new context with hiddenJournal
                proceedWithChat(query, hiddenJournal: fetchedData)
                
            } catch {
                Swift.print("❌ [ChatVM] Retrieval agent error: \(error)")
                isAssistantTyping = false
            }
        }
    }
    
    // MARK: - Save Context
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ChatVM] Context saved successfully")
        } catch {
            Swift.print("❌ [ChatVM] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stop & Reset
    func userStop() {
        Swift.print("🛑 [ChatVM] userStop invoked.")
        isUserStopping = true
        isAssistantTyping = false
    }
    
    func resetStopState() {
        isUserStopping = false
    }
    
    // MARK: - Clear Conversation
    func clearConversation() {
        sessionStart = Date()
        messages.removeAll()
        loadMessages()
        if messages.isEmpty {
            sendInitialHiddenMessage()
        }
    }
}