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
    
    // Layout constants
    private let dotDiameter: CGFloat = 18
    private let lineThickness: CGFloat = 4
    private let daySpacing: CGFloat = 60  // spacing between centers of adjacent dots
    private let extraLeft: CGFloat = 20     // original left margin for dots
    private let leftExtension: CGFloat = 30 // extend the line to the left by this amount
    
    // Compute line width: from (extraLeft - leftExtension) to right edge of the last dot.
    private var lineWidth: CGFloat {
        guard latestDates.count > 0 else { return 0 }
        let rightEdge = extraLeft + dotDiameter + CGFloat(latestDates.count - 1) * daySpacing
        return rightEdge - (extraLeft - leftExtension)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                // Draw the horizontal offWhite line.
                Rectangle()
                    .fill(UIStyles.offWhite)
                    .frame(width: lineWidth, height: lineThickness)
                    // Position the line so its left edge is at (extraLeft - leftExtension)
                    .position(x: (extraLeft - leftExtension) + lineWidth/2, y: 50)
                
                // Render the dots with thick border and filled with the app background color.
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
            }
            // The outer frame: its width accommodates the line extension.
            .frame(width: lineWidth + leftExtension, height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MoodChartView_Previews: PreviewProvider {
    static var previews: some View {
        MoodChartView()
            .frame(height: 100)
    }
}