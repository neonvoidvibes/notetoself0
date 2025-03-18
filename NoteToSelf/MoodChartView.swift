import SwiftUI

struct MoodChartView: View {
    var entries: FetchedResults<JournalEntryEntity>
    
    // Group entries by day using start of day as key
    var groupedEntries: [Date: [JournalEntryEntity]] {
        Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.timestamp ?? Date()) })
    }
    
    // Sorted list of days
    var sortedDays: [Date] {
        groupedEntries.keys.sorted()
    }
    
    // Map mood to positivity value (0.0 to 1.0)
    func positivity(for mood: String) -> Double {
        switch mood {
        case "Happy": return 1.0
        case "Excited": return 0.9
        case "Neutral": return 0.5
        case "Sad": return 0.3
        case "Stressed": return 0.2
        default: return 0.5
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Draw dotted white trend line
                Path { path in
                    var points: [CGPoint] = []
                    for day in sortedDays {
                        if let dayEntries = groupedEntries[day] {
                            let avgPos = dayEntries.compactMap { $0.mood }
                                .map { positivity(for: $0) }
                                .reduce(0, +) / Double(dayEntries.count)
                            let x = xPosition(for: day, in: geo.size.width)
                            let y = yPosition(for: avgPos, in: geo.size.height)
                            points.append(CGPoint(x: x, y: y))
                        }
                    }
                    if let first = points.first {
                        path.move(to: first)
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                
                // Draw dots for each entry on each day without any tap functionality
                ForEach(sortedDays, id: \.self) { day in
                    if let dayEntries = groupedEntries[day] {
                        let count = dayEntries.count
                        let xCenter = xPosition(for: day, in: geo.size.width)
                        let avgPos = dayEntries.compactMap { $0.mood }
                            .map { positivity(for: $0) }
                            .reduce(0, +) / Double(count)
                        let baseY = yPosition(for: avgPos, in: geo.size.height)
                        ForEach(0..<count, id: \.self) { index in
                            let offset = CGFloat(index - count/2) * 6.0
                            Circle()
                                .fill(UIStyles.moodColors[dayEntries[index].mood ?? "Neutral"] ?? Color.gray)
                                .frame(width: 12, height: 12)
                                .position(x: xCenter, y: baseY + offset)
                        }
                    }
                }
            }
        }
    }
    
    // Map a day to an x position based on the chart width.
    func xPosition(for day: Date, in width: CGFloat) -> CGFloat {
        guard let first = sortedDays.first, let last = sortedDays.last, first != last else {
            return width / 2
        }
        let total = last.timeIntervalSince(first)
        let current = day.timeIntervalSince(first)
        return CGFloat(current / total) * width
    }
    
    // Map a positivity value to a y position (inverted so higher positivity is higher up)
    func yPosition(for positivity: Double, in height: CGFloat) -> CGFloat {
        return CGFloat((1.0 - positivity)) * height
    }
}