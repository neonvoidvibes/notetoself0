import SwiftUI

struct MoodChartView: View {
    var entries: FetchedResults<JournalEntryEntity>
    
    var groupedEntries: [Date: [JournalEntryEntity]] {
        Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.timestamp ?? Date()) })
    }
    
    var sortedDays: [Date] {
        groupedEntries.keys.sorted()
    }
    
    func positivity(for mood: String) -> Double {
        switch mood.baseMood() {
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
                Path { path in
                    var points: [CGPoint] = []
                    for day in sortedDays {
                        if let dayEntries = groupedEntries[day] {
                            let avgPos = dayEntries.compactMap { entry -> Double? in
                                guard let mood = entry.mood else { return nil }
                                return positivity(for: mood)
                            }.reduce(0, +) / Double(dayEntries.count)
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
                
                ForEach(sortedDays, id: \.self) { day in
                    if let dayEntries = groupedEntries[day] {
                        let count = dayEntries.count
                        let xCenter = xPosition(for: day, in: geo.size.width)
                        let avgPos = dayEntries.compactMap { entry -> Double? in
                            guard let mood = entry.mood else { return nil }
                            return positivity(for: mood)
                        }.reduce(0, +) / Double(count)
                        let baseY = yPosition(for: avgPos, in: geo.size.height)
                        
                        if count == 1 {
                            let mood = dayEntries.first?.mood ?? "Neutral"
                            Circle()
                                .fill(UIStyles.moodColors[mood.baseMood()]?.opacity(mood.moodOpacity()) ?? Color.gray)
                                .frame(width: 12, height: 12)
                                .position(x: xCenter, y: baseY)
                        } else {
                            ForEach(0..<count, id: \.self) { index in
                                let angle = 2 * Double.pi * Double(index) / Double(count) - Double.pi / 2
                                let radius: CGFloat = 10
                                let dx = CGFloat(cos(angle)) * radius
                                let dy = CGFloat(sin(angle)) * radius
                                let mood = dayEntries[index].mood ?? "Neutral"
                                Circle()
                                    .fill(UIStyles.moodColors[mood.baseMood()]?.opacity(mood.moodOpacity()) ?? Color.gray)
                                    .frame(width: 12, height: 12)
                                    .position(x: xCenter + dx, y: baseY + dy)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func xPosition(for day: Date, in width: CGFloat) -> CGFloat {
        guard let first = sortedDays.first, let last = sortedDays.last, first != last else {
            return width / 2
        }
        let total = last.timeIntervalSince(first)
        let current = day.timeIntervalSince(first)
        return CGFloat(current / total) * width
    }
    
    func yPosition(for positivity: Double, in height: CGFloat) -> CGFloat {
        CGFloat((1.0 - positivity)) * height
    }
}