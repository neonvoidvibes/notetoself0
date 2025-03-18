import SwiftUI

struct MoodChartView: View {
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
        // Use a ZStack to combine the line, dots, and date labels.
        ZStack {
            // The horizontal line
            Rectangle()
                .fill(UIStyles.offWhite)
                .frame(width: lineWidth, height: lineThickness)
                // Position the line: its left edge is at (extraLeft - leftExtension)
                .position(x: (extraLeft - leftExtension) + lineWidth / 2, y: 50)
            
            // Dots for each day, with thick border and filled with app background
            ForEach(latestDates.indices, id: \.self) { i in
                let xPos = extraLeft + dotDiameter/2 + CGFloat(i) * daySpacing
                Circle()
                    .fill(UIStyles.appBackground)
                    .overlay(
                        Circle().stroke(UIStyles.offWhite, lineWidth: 4)
                    )
                    .frame(width: dotDiameter, height: dotDiameter)
                    .position(x: xPos, y: 50)
            }
            
            // Date labels placed exactly below each dot.
            ForEach(latestDates.indices, id: \.self) { i in
                let xPos = extraLeft + dotDiameter/2 + CGFloat(i) * daySpacing
                Text(dateFormatter.string(from: latestDates[i]))
                    .font(UIStyles.bodyFont)
                    .foregroundColor(UIStyles.textColor)
                    // Position the date label below the dot; assume dot center is at y:50 and dot radius is 9, so place the label at y: 50 + 9 + 10 = 69.
                    .position(x: xPos, y: 75)
            }
        }
        // The overall frame should at least accommodate the line extension to the left.
        .frame(width: lineWidth + leftExtension, height: 100, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoodChartView_Previews: PreviewProvider {
    static var previews: some View {
        MoodChartView()
            .frame(height: 100)
    }
}