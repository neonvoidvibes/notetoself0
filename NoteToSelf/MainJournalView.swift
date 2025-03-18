import SwiftUI

struct MainJournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    @State private var showNewEntry = false
    
    // Define two flexible columns for the grid
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Title and "New Entry" button
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
                
                // Timeline: Use LazyVGrid with 2 columns
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(entries) { entry in
                            UIStyles.Card {
                                // Show mood and truncated text (one line)
                                if let mood = entry.mood, !mood.isEmpty {
                                    Text("Mood: \(mood)")
                                        .font(UIStyles.bodyFont)
                                        .foregroundColor(UIStyles.accentColor)
                                }
                                if let text = entry.text, !text.isEmpty {
                                    Text(text)
                                        .font(UIStyles.bodyFont)
                                        .foregroundColor(UIStyles.textColor)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                Divider()
                    .background(Color.white.opacity(0.5))
                
                // Mood Chart View added to bottom half
                MoodChartView(entries: entries)
                    .frame(height: 200)
                
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
                break
            }
        }
        return streak
    }
}