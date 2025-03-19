import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    @Published var isUserStopping: Bool = false
    @Published var messages: [ChatMessageEntity] = []
    
    private let context = PersistenceController.shared.container.viewContext
    private let chatService = GPT4ChatService.shared
    private let journalRetrievalAgent: JournalRetrievalAgent
    
    private let chatAgentSystemPrompt: String = {
        return SystemPrompts.basePrompt + "\n\n" + SystemPrompts.chatAgentPrompt
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
        Swift.print("🚀 [ChatVM] Initializing ChatViewModel...")
        self.journalRetrievalAgent = JournalRetrievalAgent(context: context)
        loadMessages()
    }
    
    private func loadMessages() {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
        request.predicate = NSPredicate(format: "timestamp >= %@", sessionStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
            Swift.print("✅ [ChatVM] Loaded \(messages.count) messages.")
            if messages.isEmpty {
                Swift.print("💬 [ChatVM] No messages found, sending initial hidden message.")
                sendInitialHiddenMessage()
            }
        } catch {
            Swift.print("❌ [ChatVM] Failed to load messages: \(error.localizedDescription)")
        }
    }
    
    func sendMessage(_ userText: String) {
        guard !isUserStopping else { return }
        Swift.print("📝 [ChatVM] Received user message: \(userText)")
        
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        handleUserMessage(userText)
    }
    
    private func handleUserMessage(_ userText: String) {
        let lowered = userText.lowercased()
        if lowered.contains("journal") || lowered.contains("data") || lowered.contains("lately") ||
           lowered.contains("recent") || lowered.contains("all") {
            handOffToJournalRetrieval(query: userText)
        } else {
            proceedWithChat(userText, hiddenJournal: nil)
        }
    }
    
    private func handOffToJournalRetrieval(query: String) {
        guard !isUserStopping else { return }
        Swift.print("🔎 [ChatVM] Handing off to JournalRetrievalAgent with query: \(query)")
        
        // 1) Generate a unique confirmation message via LLM
        isAssistantTyping = true
        Task {
            do {
                let confirmPrompt = "Please confirm: Retrieve journal entries for: \(query)"
                let confirmReply = try await chatService.sendMessage(systemPrompt: chatAgentSystemPrompt, userMessage: confirmPrompt)
                let confirmEntry = ChatMessageEntity(context: context)
                confirmEntry.id = UUID()
                confirmEntry.content = confirmReply
                confirmEntry.role = "assistant"
                confirmEntry.timestamp = Date()
                saveContext()
                messages.append(confirmEntry)
            } catch {
                Swift.print("❌ [ChatVM] Confirmation error: \(error.localizedDescription)")
            }
        }
        
        // 2) Proceed with retrieval after a short delay, showing loading dot
        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                if isUserStopping {
                    Swift.print("🛑 [ChatVM] User stopped retrieval mid-task.")
                    isAssistantTyping = false
                    return
                }
                let fetchedData = journalRetrievalAgent.fetchJournalData(query: query)
                Swift.print("🔎 [ChatVM] Journal data fetched, length: \(fetchedData.count)")
                isAssistantTyping = false
                proceedWithChat(query, hiddenJournal: fetchedData)
            } catch {
                Swift.print("❌ [ChatVM] Retrieval agent error: \(error)")
                isAssistantTyping = false
            }
        }
    }
    
    private func proceedWithChat(_ userMessage: String, hiddenJournal: String?) {
        guard !isUserStopping else { return }
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
                    return
                }
                Swift.print("🤖 [ChatVM] Received GPT-4 reply: \(reply)")
                
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                
                isAssistantTyping = false
                Swift.print("💾 [ChatVM] Saved assistant message. Total messages: \(messages.count)")
            } catch {
                Swift.print("❌ [ChatVM] GPT-4 error: \(error.localizedDescription)")
                isAssistantTyping = false
            }
        }
    }
    
    private func buildChatContext(for existingMessages: [ChatMessageEntity],
                                  hiddenJournal: String?) -> String {
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
    
    private func sendInitialHiddenMessage() {
        Task {
            isAssistantTyping = true
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
    
    private func saveContext() {
        do {
            try context.save()
            Swift.print("💾 [ChatVM] Context saved successfully")
        } catch {
            Swift.print("❌ [ChatVM] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func clearConversation() {
        sessionStart = Date()
        messages.removeAll()
        loadMessages()
    }
    
    func userStop() {
        Swift.print("🛑 [ChatVM] userStop invoked.")
        isUserStopping = true
        isAssistantTyping = false
    }
    
    func resetStopState() {
        isUserStopping = false
    }
}