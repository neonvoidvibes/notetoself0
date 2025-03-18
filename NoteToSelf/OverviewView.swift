import SwiftUI
import CoreData

struct OverviewView: View {
    @Environment(\.managedObjectContext) private var moc
    
    // MARK: - Fetch the current month’s entries
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: true)],
        predicate: NSPredicate(format: "timestamp >= %@ AND timestamp < %@",
                               argumentArray: [CalendarHelper.currentMonthStart, CalendarHelper.nextMonthStart]),
        animation: .default
    )
    private var monthlyEntries: FetchedResults<JournalEntryEntity>
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 24) {
                
                // Month Headline
                Text(CalendarHelper.monthTitle.uppercased())
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                
                // The custom "calendar" of dots
                MonthCalendarView(entries: monthlyEntries)
                
                Spacer()
            }
        }
    }
}

// MARK: - Subview representing the custom calendar for the month
struct MonthCalendarView: View {
    let entries: FetchedResults<JournalEntryEntity>
    
    // Group journal entries by day of month to get the last mood recorded for that day.
    private var dayToLastMood: [Int: String] {
        var map: [Int: String] = [:]
        for entry in entries {
            guard let ts = entry.timestamp, let mood = entry.mood else { continue }
            let dayNum = CalendarHelper.dayOfMonth(from: ts)
            map[dayNum] = mood
        }
        return map
    }
    
    // Layout: 7 columns (Mon-Sun), rows depend on offset and total days
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            // Leading placeholders for offset
            ForEach(0..<CalendarHelper.offsetForFirstDay, id: \.self) { _ in
                Circle()
                    .fill(Color.clear)
                    .frame(height: circleSize)
            }
            
            // For each day in the month, create a dot with the appropriate color.
            ForEach(1...CalendarHelper.daysInCurrentMonth, id: \.self) { day in
                Circle()
                    .fill(dayToLastMood[day].flatMap { UIStyles.moodColors[$0] } ?? UIStyles.secondaryBackground)
                    .frame(height: circleSize)
                    .overlay(
                        Text("\(day)")
                            .font(UIStyles.smallLabelFont)
                            .foregroundColor(Color.white.opacity(0.7))
                    )
            }
        }
        .padding(.top, 8)
    }
    
    // Define a dot size that is larger than in InsightsView but not overly large.
    private var circleSize: CGFloat {
        28
    }
}

// MARK: - Calendar Helper
fileprivate struct CalendarHelper {
    static private let calendar = Calendar(identifier: .gregorian)
    
    static var now: Date { Date() }
    
    // Start of the current month.
    static var currentMonthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    }
    
    // Start of the next month.
    static var nextMonthStart: Date {
        calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!
    }
    
    // Total number of days in the current month.
    static var daysInCurrentMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: now)!
        return range.count
    }
    
    // Offset for the first day; if the first day is Monday, offset = 0; if Sunday, offset = 6.
    static var offsetForFirstDay: Int {
        let weekday = calendar.component(.weekday, from: currentMonthStart)
        // Transform default (1=Sunday, 2=Monday, ...) to (Monday=1,...,Sunday=7)
        let index = ((weekday + 5) % 7) + 1
        return index - 1
    }
    
    // Month title, e.g., "March 2025".
    static var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: now)
    }
    
    // Helper to get the day-of-month integer from a date.
    static func dayOfMonth(from date: Date) -> Int {
        calendar.component(.day, from: date)
    }
}

struct OverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return OverviewView()
            .environment(\.managedObjectContext, context)
    }
}