import SwiftUI
import CoreData

struct OverviewView: View {
    @Environment(\.managedObjectContext) private var moc
    @State private var currentMonth: Date = CalendarHelper.startOfMonth(for: Date())
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 24) {
                // Header with month title and navigation arrows
                HStack {
                    // Left arrow (go to previous month)
                    if !CalendarHelper.isCurrentMonth(currentMonth) {
                        Button(action: {
                            withAnimation {
                                currentMonth = CalendarHelper.changeMonth(currentMonth, by: -1)
                            }
                        }) {
                            Image(systemName: "arrow.right") // arrow pointing right indicates going forward to current month
                                .foregroundColor(UIStyles.secondaryAccentColor)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        // Placeholder to maintain layout consistency
                        Spacer().frame(width: 44)
                    }
                    
                    Spacer()
                    
                    Text(CalendarHelper.monthTitle(for: currentMonth).uppercased())
                        .font(UIStyles.headingFont)
                        .foregroundColor(UIStyles.textColor)
                    
                    Spacer()
                    
                    // Right arrow (go to next month) if not the current month
                    if !CalendarHelper.isCurrentMonth(currentMonth) {
                        Button(action: {
                            withAnimation {
                                currentMonth = CalendarHelper.changeMonth(currentMonth, by: 1)
                            }
                        }) {
                            Image(systemName: "arrow.left") // arrow pointing left indicates moving back to current month
                                .foregroundColor(UIStyles.secondaryAccentColor)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .padding(.horizontal)
                
                // Calendar container with dots
                MonthCalendarView(baseDate: currentMonth)
                    .padding(.horizontal)
                    .transition(.slide)
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    // swipe left: go to previous month
                                    withAnimation {
                                        currentMonth = CalendarHelper.changeMonth(currentMonth, by: -1)
                                    }
                                } else if value.translation.width > 0 {
                                    // swipe right: go to next month (if not current)
                                    withAnimation {
                                        currentMonth = CalendarHelper.changeMonth(currentMonth, by: 1)
                                    }
                                }
                            }
                    )
                
                Spacer()
            }
        }
    }
}

// MonthCalendarView now accepts a baseDate to display that month.
struct MonthCalendarView: View {
    let baseDate: Date
    @FetchRequest var monthEntries: FetchedResults<JournalEntryEntity>
    
    init(baseDate: Date) {
        self.baseDate = baseDate
        // Predicate for entries in the month defined by baseDate
        let start = CalendarHelper.startOfMonth(for: baseDate)
        let end = CalendarHelper.startOfMonth(for: CalendarHelper.changeMonth(baseDate, by: 1))
        _monthEntries = FetchRequest<JournalEntryEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: true)],
            predicate: NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate),
            animation: .default
        )
    }
    
    // Compute a mapping: day -> last mood (if any)
    private var dayToLastMood: [Int: String] {
        var map: [Int: String] = [:]
        for entry in monthEntries {
            guard let ts = entry.timestamp, let mood = entry.mood else { continue }
            let dayNum = CalendarHelper.dayOfMonth(from: ts, baseDate: baseDate)
            map[dayNum] = mood
        }
        return map
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            // Placeholders for offset
            ForEach(0..<CalendarHelper.offsetForFirstDay(for: baseDate), id: \.self) { _ in
                Circle()
                    .fill(Color.clear)
                    .frame(height: circleSize)
            }
            // Days in month
            ForEach(1...CalendarHelper.daysInMonth(for: baseDate), id: \.self) { day in
                Circle()
                    .fill(dayToLastMood[day].flatMap { UIStyles.moodColors[$0] } ?? UIStyles.tertiaryBackground)
                    .frame(height: circleSize)
                    .overlay(
                        Group {
                            if dayToLastMood[day] != nil {
                                Text("\(day)")
                                    .font(UIStyles.smallLabelFont)
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                        }
                    )
            }
        }
        .padding(.top, 8)
    }
    
    private var circleSize: CGFloat { 28 }
}

// MARK: - CalendarHelper updated to work with a given baseDate.
fileprivate struct CalendarHelper {
    static private let calendar = Calendar(identifier: .gregorian)
    
    // Returns the start of the month for the given date.
    static func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    
    // Returns the number of days in the month for the given base date.
    static func daysInMonth(for baseDate: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: baseDate)!
        return range.count
    }
    
    // Computes offset for first day for the month of baseDate, with Monday as first column, Sunday as last.
    static func offsetForFirstDay(for baseDate: Date) -> Int {
        let start = startOfMonth(for: baseDate)
        let weekday = calendar.component(.weekday, from: start)
        return (weekday + 5) % 7
    }
    
    // Returns the day-of-month integer for a given date relative to baseDate.
    static func dayOfMonth(from date: Date, baseDate: Date) -> Int {
        calendar.component(.day, from: date)
    }
    
    // Returns the month title (e.g. "March 2025") for a given baseDate.
    static func monthTitle(for baseDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: baseDate)
    }
    
    // Changes the given baseDate by the specified number of months.
    static func changeMonth(_ baseDate: Date, by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: baseDate)!
    }
    
    // Checks if the given baseDate is the current month.
    static func isCurrentMonth(_ baseDate: Date) -> Bool {
        let current = startOfMonth(for: Date())
        return calendar.isDate(current, equalTo: baseDate, toGranularity: .month)
    }
}

struct OverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return OverviewView()
            .environment(\.managedObjectContext, context)
    }
}