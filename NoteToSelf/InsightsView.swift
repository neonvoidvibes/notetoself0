import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>

    // Combine the monthly calendar logic from old OverviewView
    @State private var currentMonth: Date = CalendarHelper.startOfMonth(for: Date())

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Heading
                Text("Insights")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.top, 16)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)

                // Streak placeholder
                Text("Current Streak: \(calculateStreak()) days")
                    .font(UIStyles.bodyFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)

                // Month navigation
                HStack {
                    Button(action: {
                        withAnimation {
                            currentMonth = CalendarHelper.changeMonth(currentMonth, by: -1)
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(UIStyles.accentColor)
                    }

                    Spacer()

                    Text(CalendarHelper.monthTitle(for: currentMonth))
                        .font(UIStyles.bodyFont)
                        .foregroundColor(UIStyles.textColor)

                    Spacer()

                    // Right arrow, but disable if it's after current month
                    Button(action: {
                        withAnimation {
                            let potential = CalendarHelper.changeMonth(currentMonth, by: 1)
                            if !CalendarHelper.isAfterCurrentMonth(potential) {
                                currentMonth = potential
                            }
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(
                                CalendarHelper.isAfterCurrentMonth(
                                    CalendarHelper.changeMonth(currentMonth, by: 1)
                                ) ? Color.gray : UIStyles.accentColor
                            )
                    }
                    .disabled(CalendarHelper.isAfterCurrentMonth(
                                CalendarHelper.changeMonth(currentMonth, by: 1)))
                }
                .padding(.horizontal, UIStyles.globalHorizontalPadding)

                // MonthCalendarView
                MonthCalendarView(baseDate: currentMonth)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)

                // Mood chart
                Text("Mood Chart")
                    .font(UIStyles.smallLabelFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)
                    .padding(.top, 12)

                MoodChartView(entries: Array(entries))
                    .frame(height: 180)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)

                // Additional placeholder
                Text("Additional or locked advanced analytics can appear here.")
                    .font(UIStyles.bodyFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)
                    .padding(.bottom, 24)
            }
        }
        .background(UIStyles.appBackground.ignoresSafeArea())
    }

    // Simple streak calculation: # of consecutive days from most recent entry
    private func calculateStreak() -> Int {
        // naive approach for demo; can be replaced with advanced logic
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }
        guard !sortedEntries.isEmpty else { return 0 }

        var streak = 1
        var currentCalendarDay = CalendarHelper.stripTime(sortedEntries.first?.timestamp ?? Date())
        for i in 1..<sortedEntries.count {
            let entryDay = CalendarHelper.stripTime(sortedEntries[i].timestamp ?? Date())
            // Check if consecutive day
            if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: currentCalendarDay),
               Calendar.current.isDate(entryDay, inSameDayAs: prevDay) {
                streak += 1
                currentCalendarDay = entryDay
            } else {
                break
            }
        }
        return streak
    }
}

// The old "MonthCalendarView" plus "CalendarHelper" from OverviewView
struct MonthCalendarView: View {
    let baseDate: Date
    @FetchRequest var monthEntries: FetchedResults<JournalEntryEntity>

    init(baseDate: Date) {
        self.baseDate = baseDate
        let start = CalendarHelper.startOfMonth(for: baseDate)
        let end = CalendarHelper.startOfMonth(for: CalendarHelper.changeMonth(baseDate, by: 1))
        _monthEntries = FetchRequest<JournalEntryEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: true)],
            predicate: NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate),
            animation: .default
        )
    }

    private var dayDateToLastMood: [Date: String] {
        var map: [Date: String] = [:]
        for entry in monthEntries {
            guard let ts = entry.timestamp, let mood = entry.mood else { continue }
            let dayFloor = CalendarHelper.stripTime(ts)
            map[dayFloor] = mood
        }
        return map
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let start = CalendarHelper.startOfMonth(for: baseDate)
        let daysCount = CalendarHelper.daysInMonth(for: baseDate)
        let offset = CalendarHelper.offsetForFirstDay(for: baseDate)

        LazyVGrid(columns: columns, spacing: 16) {
            // Offset
            ForEach(0..<offset, id: \.self) { _ in
                Circle()
                    .fill(Color.clear)
                    .frame(height: 28)
            }
            // Days
            ForEach(1...daysCount, id: \.self) { dayIndex in
                let realDate = CalendarHelper.calendar.date(byAdding: .day, value: dayIndex - 1, to: start)!
                let dayFloor = CalendarHelper.stripTime(realDate)

                if let mood = dayDateToLastMood[dayFloor] {
                    // Mark day with mood color
                    let base = mood.baseMood()
                    let opacity = mood.moodOpacity()
                    if let color = UIStyles.moodColors[base] {
                        Circle()
                            .fill(color.opacity(opacity))
                            .frame(height: 28)
                            .overlay(
                                Text("\(dayIndex)")
                                    .font(UIStyles.smallLabelFont)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    } else {
                        Circle()
                            .fill(UIStyles.tertiaryBackground)
                            .frame(height: 28)
                            .overlay(
                                Text("\(dayIndex)")
                                    .font(UIStyles.smallLabelFont)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                } else {
                    // No entry
                    Circle()
                        .fill(UIStyles.tertiaryBackground)
                        .frame(height: 28)
                        .overlay(
                            Text("\(dayIndex)")
                                .font(UIStyles.smallLabelFont)
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
        }
        .padding(.top, 8)
    }
}

// CalendarHelper from OverviewView
struct CalendarHelper {
    static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday = 2
        return cal
    }()

    static func startOfMonth(for date: Date) -> Date {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return date
        }
        // anchor at midday to avoid DST weirdness
        let anchored = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: interval.start) ?? interval.start
        return anchored
    }

    static func daysInMonth(for date: Date) -> Int {
        let start = startOfMonth(for: date)
        let range = calendar.range(of: .day, in: .month, for: start) ?? (1..<2)
        return range.count
    }

    static func offsetForFirstDay(for date: Date) -> Int {
        let start = startOfMonth(for: date)
        let weekday = calendar.component(.weekday, from: start)
        // Monday-based offset
        return ((weekday + 7) - calendar.firstWeekday) % 7
    }

    static func stripTime(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }

    static func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func changeMonth(_ baseDate: Date, by value: Int) -> Date {
        return calendar.date(byAdding: .month, value: value, to: baseDate) ?? baseDate
    }

    static func isCurrentMonth(_ baseDate: Date) -> Bool {
        let current = startOfMonth(for: Date())
        return calendar.isDate(current, equalTo: baseDate, toGranularity: .month)
    }

    static func isAfterCurrentMonth(_ baseDate: Date) -> Bool {
        let current = startOfMonth(for: Date())
        return baseDate > current
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return InsightsView().environment(\.managedObjectContext, context)
    }
}