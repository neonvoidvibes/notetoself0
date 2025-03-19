import Foundation
import CoreData

/// A specialized agent that retrieves journal entries based on timeframe or user query.
/// This agent is used by the Chat Agent to fetch data. It does not directly display UI messages.
final class JournalRetrievalAgent {
    
    private let context: NSManagedObjectContext
    private let systemPrompt: String

    init(context: NSManagedObjectContext) {
        self.context = context
        // Combine basePrompt + retrievalAgentPrompt
        self.systemPrompt = SystemPrompts.basePrompt + "\n\n" + SystemPrompts.journalRetrievalAgentPrompt
    }
    
    /// Retrieve entries from the last N days or all entries
    /// For now, we simulate direct fetch from Core Data
    func retrieveEntries(forLastNDays days: Int?) -> [JournalEntryEntity] {
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        if let d = days {
            // Since date
            let sinceDate = Calendar.current.date(byAdding: .day, value: -d, to: Date()) ?? Date.distantPast
            request.predicate = NSPredicate(format: "timestamp >= %@", sinceDate as NSDate)
        } else {
            // if days is nil, retrieve all entries
            request.predicate = nil
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ [JournalRetrievalAgent] Failed to fetch: \(error)")
            return []
        }
    }
    
    /// Main API: returns a short textual representation of the requested data
    /// This is called by the Chat Agent.
    func fetchJournalData(query: String) -> String {
        // parse the query for "lately" => last 7 days, "all" => all entries, etc.
        // for a more advanced approach, we could do better NLP, but let's keep it simple
        let normalized = query.lowercased()
        let days: Int? = {
            if normalized.contains("lately") || normalized.contains("recent") {
                return 7
            } else if normalized.contains("all") || normalized.contains("everything") {
                return nil
            } else {
                // fallback - assume no special timeframe => last 7 days
                return 7
            }
        }()
        
        let entries = retrieveEntries(forLastNDays: days)
        if entries.isEmpty {
            return "No entries found for that timeframe."
        }
        
        // Build a short summary
        var lines: [String] = []
        for entry in entries {
            let dateStr = entry.timestamp?.formatted(date: .numeric, time: .omitted) ?? "Unknown"
            let mood = entry.mood ?? "N/A"
            let txt = entry.text ?? ""
            lines.append("[\(dateStr)] (\(mood)) \(txt)")
        }
        
        // limit to some lines if large
        let maxCount = min(lines.count, 20)
        let chunk = lines.prefix(maxCount).joined(separator: "\n")
        return chunk
    }
}