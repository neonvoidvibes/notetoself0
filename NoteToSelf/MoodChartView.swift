import SwiftUI

struct MoodChartView: View {
    // Changed entries type to [JournalEntryEntity] for easier preview and conversion.
    var entries: [JournalEntryEntity]
    
    // Group entries by day (using the start of the day).
    var groupedEntries: [Date: [JournalEntryEntity]] {
        Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.timestamp ?? Date()) })
    }
    
    // Build a continuous list of days from the first to the last entry.
    var allDays: [Date] {
        let sortedDays = groupedEntries.keys.sorted()
        guard let first = sortedDays.first, let last = sortedDays.last else {
            return []
        }
        var days: [Date] = []
        var current = first
        while current <= last {
            days.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Horizontal scroll view containing the timeline.
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        ZStack {
                            // Draw a thick horizontal offWhite line centered vertically.
                            Rectangle()
                                .fill(UIStyles.offWhite)
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, (geo.size.height - 4) / 2)
                            
                            // Evenly distribute all dots along the line.
                            HStack {
                                ForEach(allDays.indices, id: \.self) { i in
                                    dotView(for: allDays[i])
                                        .id(i)
                                    if i != allDays.indices.last {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onAppear {
                            scrollProxy = proxy
                            // Scroll to the last (latest) dot on appear.
                            if let lastIndex = allDays.indices.last {
                                DispatchQueue.main.async {
                                    proxy.scrollTo(lastIndex, anchor: .trailing)
                                }
                            }
                        }
                    }
                }
                // Show arrow button if there are enough dots to require scrolling.
                if shouldShowRightArrow(geo: geo) {
                    Button {
                        if let lastIndex = allDays.indices.last {
                            scrollProxy?.scrollTo(lastIndex, anchor: .trailing)
                        }
                    } label: {
                        Image(systemName: "arrow.right.to.line")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(UIStyles.secondaryAccentColor)
                    }
                    .padding()
                }
            }
        }
        .frame(height: 100)
    }
    
    // Build a view for each day: a dot (filled if entry exists, otherwise outlined) and a date label.
    private func dotView(for day: Date) -> some View {
        VStack(spacing: 4) {
            if let avg = averagePositivity(for: day) {
                Circle()
                    .fill(colorForPositivity(avg))
                    .frame(width: 18, height: 18)
            } else {
                Circle()
                    .stroke(UIStyles.offWhite, lineWidth: 2)
                    .frame(width: 18, height: 18)
            }
            Text(shortDateString(day))
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
        }
        // Ensure each dot view has a fixed minimum width.
        .frame(minWidth: 18)
    }
    
    // Calculate average positivity for a given day.
    private func averagePositivity(for day: Date) -> Double? {
        guard let entriesForDay = groupedEntries[day], !entriesForDay.isEmpty else { return nil }
        let total = entriesForDay.compactMap { entry -> Double? in
            guard let mood = entry.mood else { return nil }
            return positivity(for: mood)
        }.reduce(0, +)
        return total / Double(entriesForDay.count)
    }
    
    // Map a mood string to a positivity value.
    private func positivity(for mood: String) -> Double {
        switch mood.baseMood() {
        case "Happy": return 1.0
        case "Excited": return 0.9
        case "Neutral": return 0.5
        case "Sad": return 0.3
        case "Stressed": return 0.2
        default: return 0.5
        }
    }
    
    // Determine the color for a given positivity value.
    private func colorForPositivity(_ val: Double) -> Color {
        if val >= 0.8 { return UIStyles.moodColors["Happy"] ?? .yellow }
        if val >= 0.6 { return UIStyles.moodColors["Excited"] ?? .orange }
        if val >= 0.4 { return .gray }
        if val >= 0.25 { return .blue }
        return .red
    }
    
    // Format the date into a short string.
    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Decide whether to show the arrow button based on the number of days.
    private func shouldShowRightArrow(geo: GeometryProxy) -> Bool {
        return allDays.count > 3
    }
}

struct MoodChartView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, pass an empty array (or populate with dummy JournalEntryEntity objects if available).
        MoodChartView(entries: [])
            .frame(height: 120)
    }
}