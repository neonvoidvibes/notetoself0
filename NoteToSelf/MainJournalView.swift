import SwiftUI

struct MainJournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    @State private var showNewEntry = false
    @State private var showInsights = false  // Toggle for chart view
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Title only (left-aligned)
                Text("Note to Self")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(UIStyles.textColor)
                
                // "+ Add" button positioned just above the entries, right-aligned
                HStack {
                    Spacer()
                    Button {
                        showNewEntry.toggle()
                    } label: {
                        Text("+ Add")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(Color.black)  // Text on accent bg is black
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(UIStyles.accentColor)
                            .cornerRadius(UIStyles.defaultCornerRadius)
                    }
                }
                
                // Daily Streak Info
                DailyStreakView(entries: entries)
                
                // Timeline: Full-width entries in a LazyVStack
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            HStack {
                                if let text = entry.text, !text.isEmpty {
                                    Text(text)
                                        .font(UIStyles.bodyFont)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let mood = entry.mood, !mood.isEmpty,
                                   let moodColor = UIStyles.moodColors[mood] {
                                    Circle()
                                        .fill(moodColor)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .padding()
                            .background(UIStyles.entryBackground)
                            .cornerRadius(UIStyles.defaultCornerRadius)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Chart header: "Notes" and "Insights" left-adjusted with larger font
                HStack(spacing: 20) {
                    Button(action: {
                        showInsights = false
                    }) {
                        Text("Notes")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(showInsights ? Color.gray : UIStyles.accentColor)
                    }
                    Button(action: {
                        showInsights = true
                    }) {
                        Text("Insights")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(showInsights ? UIStyles.accentColor : Color.gray)
                    }
                }
                .padding(.leading, UIStyles.globalHorizontalPadding)
                
                // Chart area: Swap between MoodChartView and Insights placeholder
                if showInsights {
                    VStack {
                        Text("Insights coming soon")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(UIStyles.textColor)
                        Spacer()
                    }
                    .frame(height: 200)
                } else {
                    MoodChartView(entries: entries)
                        .frame(height: 200)
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