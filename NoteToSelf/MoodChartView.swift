import SwiftUI

struct MoodChartView: View {
    var entries: [JournalEntryEntity]
    
    // Group journal entries by the start of their day.
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
    
    // Date formatter to show only the day number.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    // Layout constants.
    private let dotDiameter: CGFloat = 18
    private let lineThickness: CGFloat = 4
    private let daySpacing: CGFloat = 60   // Spacing between centers of adjacent dots.
    private let extraLeft: CGFloat = 20      // Original left margin for dots.
    private let leftExtension: CGFloat = 30  // How far to extend the line to the left.
    
    // Compute the width of the horizontal line (from extraLeft - leftExtension to the right edge of the last dot).
    private var lineWidth: CGFloat {
        guard latestDates.count > 0 else { return 0 }
        let rightEdge = extraLeft + dotDiameter + CGFloat(latestDates.count - 1) * daySpacing
        return rightEdge - (extraLeft - leftExtension)
    }
    
    // Determines the color for the date label based on journal entry mood.
    // If there is a journal entry for that day, returns the mood color of the latest entry; otherwise, returns tertiaryBackground.
    private func dateColor(for day: Date) -> Color {
        if let dayEntries = groupedEntries[day], !dayEntries.isEmpty {
            let latestEntry = dayEntries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }.first
            let mood = latestEntry?.mood ?? ""
            return UIStyles.moodColors[mood.baseMood()] ?? UIStyles.tertiaryBackground
        } else {
            return UIStyles.tertiaryBackground
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Draw the horizontal line; extend it from (extraLeft - leftExtension) to the right edge of the last dot.
                Rectangle()
                    .fill(UIStyles.secondaryAccentColor)
                    .frame(width: lineWidth, height: lineThickness)
                    .position(x: (extraLeft - leftExtension) + lineWidth/2, y: 50)
                
                // Render a dot for each of the 5 latest days.
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
                        .foregroundColor(dateColor(for: latestDates[i]))
                        .position(x: xPos, y: 75)
                }
            }
            .frame(width: lineWidth + leftExtension, height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Render a dot for a given day.
    private func dotView(for day: Date) -> some View {
        if let dayEntries = groupedEntries[day], !dayEntries.isEmpty {
            // If there are entries for this day, fill the dot with the mood color from the latest entry.
            let latestEntry = dayEntries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }.first
            let mood = latestEntry?.mood ?? ""
            let moodColor = UIStyles.moodColors[mood.baseMood()] ?? Color.gray
            return AnyView(
                Circle()
                    .fill(moodColor)
                    .overlay(
                        Circle().stroke(moodColor, lineWidth: 4)
                    )
                    .frame(width: dotDiameter, height: dotDiameter)
            )
        } else {
            // No entry: draw an outlined dot with thick border.
            return AnyView(
                Circle()
                    .fill(UIStyles.appBackground)
                    .overlay(
                        Circle().stroke(UIStyles.secondaryAccentColor, lineWidth: 4)
                    )
                    .frame(width: dotDiameter, height: dotDiameter)
            )
        }
    }
}

struct MoodChartView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, pass an empty array or provide dummy JournalEntryEntity objects.
        MoodChartView(entries: [])
            .frame(height: 100)
    }
}