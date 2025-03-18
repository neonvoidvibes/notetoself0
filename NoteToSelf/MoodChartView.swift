import SwiftUI

struct MoodChartView: View {
    // Accept journal entries
    var entries: [JournalEntryEntity]
    
    // Group entries by startOfDay
    private var groupedEntries: [Date: [JournalEntryEntity]] {
        Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.timestamp ?? Date()) })
    }
    
    // Generate 5 latest days: from 4 days ago to today.
    private var latestDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -(4 - i), to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Only day number
        return formatter
    }
    
    // Layout constants
    private let dotDiameter: CGFloat = 18
    private let lineThickness: CGFloat = 4
    private let daySpacing: CGFloat = 60  // Spacing between centers of adjacent dots
    private let extraLeft: CGFloat = 20     // Original left margin for dots
    private let leftExtension: CGFloat = 30 // Extend the line to the left by this amount
    
    // Total content width for dots: from extraLeft to right edge of last dot.
    private var dotsContentWidth: CGFloat {
        guard latestDates.count > 0 else { return 0 }
        return extraLeft + dotDiameter + CGFloat(latestDates.count - 1) * daySpacing
    }
    
    // The line width extends from (extraLeft - leftExtension) to the right edge of the last dot.
    private var lineWidth: CGFloat {
        guard latestDates.count > 0 else { return 0 }
        let rightEdge = extraLeft + dotDiameter + CGFloat(latestDates.count - 1) * daySpacing
        return rightEdge - (extraLeft - leftExtension)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Container for the horizontal line, dots, and date labels.
            ZStack {
                // Draw the horizontal offWhite line, extending from (extraLeft - leftExtension) to last dot.
                Rectangle()
                    .fill(UIStyles.offWhite)
                    .frame(width: lineWidth, height: lineThickness)
                    .position(x: (extraLeft - leftExtension) + lineWidth/2, y: 50)
                
                // Render dots for each day.
                ForEach(latestDates.indices, id: \.self) { i in
                    let xPos = extraLeft + dotDiameter/2 + CGFloat(i) * daySpacing
                    dotView(for: latestDates[i])
                        .position(x: xPos, y: 50)
                }
                
                // Render date labels directly below each dot.
                ForEach(latestDates.indices, id: \.self) { i in
                    let xPos = extraLeft + dotDiameter/2 + CGFloat(i) * daySpacing
                    Text(dateFormatter.string(from: latestDates[i]))
                        .font(UIStyles.bodyFont)
                        .foregroundColor(UIStyles.textColor)
                        .position(x: xPos, y: 75)
                }
            }
            .frame(width: lineWidth + leftExtension, height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Render a dot for a given day.
    private func dotView(for day: Date) -> some View {
        // Check if there are any journal entries for this day.
        if let dayEntries = groupedEntries[day], !dayEntries.isEmpty {
            // Sort entries by timestamp descending, take the latest.
            let latestEntry = dayEntries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }.first
            let mood = latestEntry?.mood ?? ""
            let moodColor = UIStyles.moodColors[mood.baseMood()] ?? Color.gray
            return AnyView(
                Circle()
                    .fill(moodColor)
                    .frame(width: dotDiameter, height: dotDiameter)
            )
        } else {
            // No entry: outlined dot.
            return AnyView(
                Circle()
                    .fill(UIStyles.appBackground)
                    .overlay(
                        Circle().stroke(UIStyles.offWhite, lineWidth: 4)
                    )
                    .frame(width: dotDiameter, height: dotDiameter)
            )
        }
    }
}

struct MoodChartView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, create dummy entries if needed. Here we pass an empty array.
        MoodChartView(entries: [])
            .frame(height: 100)
    }
}