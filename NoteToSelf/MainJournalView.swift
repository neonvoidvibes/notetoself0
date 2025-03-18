import SwiftUI

struct MainJournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    @State private var showNewEntry = false
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                
                // Title + "New Entry" button
                HStack {
                    Text("Daily Journal")
                        .font(UIStyles.headingFont)
                        .foregroundColor(UIStyles.textColor)
                    Spacer()
                    Button {
                        showNewEntry.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(UIStyles.accentColor)
                    }
                }
                
                // Daily Streak Info
                DailyStreakView(entries: entries)
                
                // Timeline List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(entries) { entry in
                            UIStyles.Card {
                                Text(entry.timestamp ?? Date(), style: .date)
                                    .font(UIStyles.smallLabelFont)
                                    .foregroundColor(UIStyles.textColor.opacity(0.6))
                                if let mood = entry.mood, !mood.isEmpty {
                                    Text("Mood: \(mood)")
                                        .font(UIStyles.bodyFont)
                                        .foregroundColor(UIStyles.accentColor)
                                }
                                if let text = entry.text, !text.isEmpty {
                                    Text(text)
                                        .font(UIStyles.bodyFont)
                                        .foregroundColor(UIStyles.textColor)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showNewEntry) {
                NewEntrySheet()
            }
        }
    }
}

struct DailyStreakView: View {
    let entries: FetchedResults<JournalEntryEntity>
    
    var body: some View {
        let streakCount = calculateStreak()
        return HStack {
            Text("Current Streak: \(streakCount) day\(streakCount == 1 ? "" : "s")")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
        }
    }
    
    func calculateStreak() -> Int {
        // Simple logic: check consecutive days
        // Sort by date descending and see how many consecutive calendar days
        let sorted = entries.sorted { $0.timestamp ?? Date() > $1.timestamp ?? Date() }
        guard !sorted.isEmpty else { return 0 }
        
        var streak = 1
        var previousDate = Calendar.current.startOfDay(for: sorted[0].timestamp ?? Date())
        
        for i in 1..<sorted.count {
            let currentDate = Calendar.current.startOfDay(for: sorted[i].timestamp ?? Date())
            let diff = Calendar.current.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0
            if diff == 1 {
                streak += 1
                previousDate = currentDate
            } else if diff > 1 {
                // Streak broken
                break
            }
        }
        return streak
    }
}
