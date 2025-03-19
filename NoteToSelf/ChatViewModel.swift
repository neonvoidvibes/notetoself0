import Foundation
import CoreData
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var isAssistantTyping: Bool = false
    @Published var isAgentWorking: Bool = false       // new flag for multi-agent tasks
    @Published var isUserStopping: Bool = false       // user pressed "stop"
    @Published var messages: [ChatMessageEntity] = []
    
    // track a "current status message" for agent tasks
    @Published var agentStatusMessage: String? = nil
    
    private let context = PersistenceController.shared.container.viewContext
    
    private let chatService = GPT4ChatService.shared
    
    // Agents
    private let journalRetrievalAgent: JournalRetrievalAgent
    
    // The Chat agent's system prompt is the combo of basePrompt + chatAgentPrompt
    // We store it once.
    private let chatAgentSystemPrompt: String = {
        return SystemPrompts.basePrompt + "\n\n" + SystemPrompts.chatAgentPrompt
    }()
    
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

    init() {
        Swift.print("🚀 [ChatVM] Initializing ChatViewModel (multi-agent)...")
        // create retrieval agent
        self.journalRetrievalAgent = JournalRetrievalAgent(context: context)
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
    
    // user tapped Send
    func sendMessage(_ userText: String) {
        guard !isUserStopping else { return } // if user pressed stop, ignore new messages
        Swift.print("📝 [ChatVM] Received user message: \(userText)")
        
        let userEntry = ChatMessageEntity(context: context)
        userEntry.id = UUID()
        userEntry.content = userText
        userEntry.role = "user"
        userEntry.timestamp = Date()
        saveContext()
        messages.append(userEntry)
        
        // now check if we might need to do a retrieval
        handleUserMessage(userText)
    }
    
    private func handleUserMessage(_ userText: String) {
        // If user references "journal," "lately," "recent," or "all," let's do a retrieval
        let lowered = userText.lowercased()
        if lowered.contains("journal") || lowered.contains("data") || lowered.contains("lately") || lowered.contains("recent") || lowered.contains("all") {
            // attempt handoff to the retrieval agent
            handOffToJournalRetrieval(query: userText)
        } else {
            // no retrieval needed, proceed with normal chat
            proceedWithChat(userText, hiddenJournal: nil)
        }
    }
    
    private func handOffToJournalRetrieval(query: String) {
        guard !isUserStopping else { return }
        Swift.print("🔎 [ChatVM] Handing off to JournalRetrievalAgent with query: \(query)")
        
        // show status message
        agentStatusMessage = "Retrieving journal..."
        isAgentWorking = true
        
        Task {
            do {
                // simulate short delay
                try await Task.sleep(nanoseconds: 300_000_000)
                
                if isUserStopping {
                    Swift.print("🛑 [ChatVM] User stopped retrieval mid-task.")
                    isAgentWorking = false
                    agentStatusMessage = nil
                    return
                }
                
                let fetchedData = journalRetrievalAgent.fetchJournalData(query: query)
                Swift.print("🔎 [ChatVM] Journal data fetched, length: \(fetchedData.count)")
                
                // we now proceed with normal chat, passing the fetched data as hidden context
                isAgentWorking = false
                agentStatusMessage = nil
                
                proceedWithChat(query, hiddenJournal: fetchedData)
                
            } catch {
                Swift.print("❌ [ChatVM] Retrieval agent error: \(error)")
                isAgentWorking = false
                agentStatusMessage = nil
            }
        }
    }
    
    private func proceedWithChat(_ userMessage: String, hiddenJournal: String?) {
        guard !isUserStopping else { return }
        // Build conversation context
        isAssistantTyping = true
        let chatHistoryContext = buildChatContext(for: messages, hiddenJournal: hiddenJournal)
        Swift.print("📜 [ChatVM] Sending conversation context:\n\(chatHistoryContext)")
        
        Task {
            do {
                Swift.print("🤖 [ChatVM] Sending context to GPT-4o with chatAgentPrompt...")
                let reply = try await chatService.sendMessage(
                    systemPrompt: chatAgentSystemPrompt,
                    userMessage: chatHistoryContext
                )
                if isUserStopping {
                    Swift.print("🛑 [ChatVM] Stopped after chat request returned, discarding.")
                    isAssistantTyping = false
                    return
                }
                Swift.print("🤖 [ChatVM] Received GPT-4o reply: \(reply)")
                
                let assistantEntry = ChatMessageEntity(context: context)
                assistantEntry.id = UUID()
                assistantEntry.content = reply
                assistantEntry.role = "assistant"
                assistantEntry.timestamp = Date()
                saveContext()
                messages.append(assistantEntry)
                isAssistantTyping = false
                Swift.print("💾 [ChatVM] Saved assistant message locally. Total messages: \(messages.count)")
            } catch {
                Swift.print("❌ [ChatVM] Error calling GPT-4o: \(error.localizedDescription)")
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
                Swift.print("💾 [ChatVM] Saved initial assistant message locally. Total messages: \(messages.count)")
                isAssistantTyping = false
            } catch {
                Swift.print("❌ [ChatVM] Error sending initial hidden message: \(error.localizedDescription)")
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
    
    /// Called when user presses "Stop"
    func userStop() {
        Swift.print("🛑 [ChatVM] userStop invoked.")
        isUserStopping = true
        isAssistantTyping = false
        isAgentWorking = false
        agentStatusMessage = nil
    }
    
    /// Called once we've confirmed the user wants to resume
    func resetStopState() {
        isUserStopping = false
    }
}