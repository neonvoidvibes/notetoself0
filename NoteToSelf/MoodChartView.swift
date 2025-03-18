import SwiftUI

struct MoodChartView: View {
    var entries: FetchedResults<JournalEntryEntity>
    
    // We'll track the scroll offset to decide whether to show the "arrow.right.to.line" button.
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    // For ScrollViewReader to jump back to the latest day
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    // A day is considered to have entries if found in groupedEntries
    var groupedEntries: [Date: [JournalEntryEntity]] {
        Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.timestamp ?? Date()) })
    }
    
    // We gather a continuous list of days from the earliest to the latest (based on entries).
    var allDays: [Date] {
        let sortedDays = groupedEntries.keys.sorted()
        guard let earliest = sortedDays.first,
              let latest = sortedDays.last else {
            // No entries => Return empty to avoid errors
            return []
        }
        // build a day-by-day array
        var days: [Date] = []
        var current = earliest
        let end = Calendar.current.startOfDay(for: latest)
        
        while current <= end {
            days.append(current)
            if let next = Calendar.current.date(byAdding: .day, value: 1, to: current) {
                current = next
            } else {
                break
            }
        }
        return days
    }
    
    // We'll compute an average positivity for each day, if any
    func averagePositivity(for day: Date) -> Double? {
        guard let dayEntries = groupedEntries[day], !dayEntries.isEmpty else {
            return nil
        }
        let sum = dayEntries.compactMap { entry -> Double? in
            guard let mood = entry.mood else { return nil }
            return positivity(for: mood)
        }.reduce(0, +)
        return sum / Double(dayEntries.count)
    }
    
    // A simplified positivity measure for the base mood string
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
            ZStack(alignment: .topTrailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    // We'll track content width & offset by reading the geometry in a background
                    ScrollViewReader { proxy in
                        // Our line & circles in an HStack
                        HStack(alignment: .center, spacing: 40) {
                            ForEach(allDays.indices, id: \.self) { i in
                                let day = allDays[i]
                                // We'll draw the line to the next day inside a background if i < count-1
                                ZStack {
                                    // Draw connecting line behind each day, going to next day
                                    lineToNextDay(currentIndex: i)
                                    
                                    // The mood circle or an empty circle
                                    circleForDay(day)
                                    
                                    // The date label below
                                    VStack {
                                        Spacer().frame(height: 40) // spacing so circle can appear on the center line
                                        Text(shortDateString(day))
                                            .font(UIStyles.bodyFont)
                                            .foregroundColor(UIStyles.textColor)
                                            .frame(width: 50)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .id(i) // For scrollTo
                            }
                        }
                        .frame(height: geo.size.height)  // expand to container's height
                        .onAppear {
                            scrollProxy = proxy
                            containerWidth = geo.size.width
                            
                            // Jump to the rightmost day on first appear
                            if !allDays.isEmpty {
                                let lastIndex = allDays.count - 1
                                DispatchQueue.main.async {
                                    proxy.scrollTo(lastIndex, anchor: .trailing)
                                }
                            }
                        }
                        .background(
                            GeometryReader { contentGeo in
                                Color.clear.onAppear {
                                    scrollWidth = contentGeo.size.width
                                }
                                .onChange(of: contentGeo.size.width) { newVal in
                                    scrollWidth = newVal
                                }
                            }
                        )
                        .onChange(of: scrollOffset) { _ in
                            // If we're scrolled away from the right edge, show arrow
                            // i.e. if (scrollOffset + containerWidth < scrollWidth)
                            // We'll handle that logic in a computed var
                        }
                        // We'll track offset via a DragGesture or preference key
                        .gesture(
                            DragGesture().onChanged { value in
                                let translation = value.translation.width
                                // negative translation => scrolling left
                                // We need a simpler approach for offset. We'll accumulate
                                // but it's tricky. Let's do a simpler approach with .coordinateSpace
                            }
                        )
                    }
                    .coordinateSpace(name: "chartScroll")
                    .mask( // Fade left edge slightly
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0), location: 0),
                                .init(color: Color.black, location: 0.05),
                                .init(color: Color.black, location: 0.95),
                                .init(color: Color.black.opacity(1.0), location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                
                // The "arrow.right.to.line" button if the user is scrolled away from the latest day
                if shouldShowRightArrow {
                    Button {
                        // Jump to the last day
                        if !allDays.isEmpty {
                            let lastIndex = allDays.count - 1
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
    }
    
    // Decide if arrow is shown based on whether the user is fully scrolled to the right
    // We'll just approximate that if scrollWidth > containerWidth + offset by more than a few px, show it
    private var shouldShowRightArrow: Bool {
        // We haven't fully implemented offset tracking. For demonstration, let's just guess:
        // If there's more than one day, we show the arrow if the user might be left of the last day.
        // A more robust approach is to track offset precisely. We'll do a simpler approach here.
        return allDays.count > 1
    }
    
    // We draw a line from day i to i+1
    @ViewBuilder
    private func lineToNextDay(currentIndex i: Int) -> some View {
        if i < allDays.count - 1 {
            // A horizontal line from the center of this day to the center of next day
            // We'll just draw a rectangle behind the circle, since each day is spaced 40 apart in HStack
            Rectangle()
                .fill(UIStyles.offWhite)
                .frame(width: 40, height: 2)
                .offset(x: 20, y: 0) // to start from circle center
        }
    }
    
    // The mood circle or an empty circle for a day
    @ViewBuilder
    private func circleForDay(_ day: Date) -> some View {
        let hasEntry = groupedEntries[day] != nil
        if hasEntry, let avgPos = averagePositivity(for: day) {
            // We find the "base" mood color from the average
            // We'll pick a color based on the positivity scale, or approximate
            let color = colorForPositivity(avgPos)
            Circle()
                .fill(color)
                .frame(width: 18, height: 18)
                .offset(y: -10) // center line
        } else {
            // No entry => show offWhite border, fill with background color
            Circle()
                .stroke(UIStyles.offWhite, lineWidth: 2)
                .background(Circle().fill(UIStyles.appBackground))
                .frame(width: 18, height: 18)
                .offset(y: -10)
        }
    }
    
    private func colorForPositivity(_ val: Double) -> Color {
        // We can approximate. If val near 1 => bright color, near 0 => more negative color
        // Or we can reuse the base approach from positivity(for: mood).
        // For simplicity, let's do a gradient scale:
        if val >= 0.8 { return UIStyles.moodColors["Happy"] ?? .yellow }
        if val >= 0.6 { return UIStyles.moodColors["Excited"] ?? .orange }
        if val >= 0.4 { return .gray }
        if val >= 0.25 { return .blue }
        return .red
    }
    
    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}