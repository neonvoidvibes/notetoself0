import SwiftUI
import CoreData

struct OverviewView: View {
    @Environment(\.managedObjectContext) private var moc
    @State private var currentMonth: Date = CalendarHelper.startOfMonth(for: Date())
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(CalendarHelper.monthTitle(for: currentMonth).uppercased())
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                
                HStack {
                    Button(action: {
                        withAnimation {
                            currentMonth = CalendarHelper.changeMonth(currentMonth, by: -1)
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(UIStyles.secondaryAccentColor)
                    }
                    
                    Spacer()
                    
                    if !CalendarHelper.isCurrentMonth(currentMonth) {
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
                                .frame(width: 40, height: 40)
                                .foregroundColor(UIStyles.secondaryAccentColor)
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    withAnimation {
                                        currentMonth = CalendarHelper.startOfMonth(for: Date())
                                    }
                                }
                        )
                    } else {
                        Spacer().frame(width: 40)
                    }
                }
                
                MonthCalendarView(baseDate: currentMonth)
                    .transition(.slide)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.width > 0 {
                                    withAnimation {
                                        currentMonth = CalendarHelper.changeMonth(currentMonth, by: -1)
                                    }
                                } else if value.translation.width < 0 {
                                    let potential = CalendarHelper.changeMonth(currentMonth, by: 1)
                                    if !CalendarHelper.isAfterCurrentMonth(potential) {
                                        withAnimation {
                                            currentMonth = potential
                                        }
                                    }
                                }
                            }
                    )
                
                Spacer()
            }
        }
    }
}

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
            ForEach(0..<offset, id: \.self) { index in
                Circle()
                    .fill(Color.clear)
                    .frame(height: circleSize)
                    .id("offset-\(index)")
            }
            ForEach(1...daysCount, id: \.self) { dayIndex in
                let realDate = CalendarHelper.calendar.date(byAdding: .day, value: dayIndex - 1, to: start)!
                let dayFloor = CalendarHelper.stripTime(realDate)
                let mood = dayDateToLastMood[dayFloor]
                if let mood = mood {
                    Circle()
                        .fill(UIStyles.moodColors[mood.baseMood()]?.opacity(mood.moodOpacity()) ?? UIStyles.tertiaryBackground)
                        .frame(height: circleSize)
                        .overlay(
                            Text("\(dayIndex)")
                                .font(UIStyles.smallLabelFont)
                                .foregroundColor(Color.white.opacity(0.7))
                        )
                        .id("day-\(dayIndex)")
                } else {
                    Circle()
                        .fill(UIStyles.tertiaryBackground)
                        .frame(height: circleSize)
                        .id("day-\(dayIndex)")
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var circleSize: CGFloat { 28 }
}

struct CalendarHelper {
    static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }()
    
    static func startOfMonth(for date: Date) -> Date {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return date
        }
        let anchored = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: interval.start) ?? interval.start
        return anchored
    }
    
    static func daysInMonth(for baseDate: Date) -> Int {
        let start = startOfMonth(for: baseDate)
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<2
        return range.count
    }
    
    static func offsetForFirstDay(for baseDate: Date) -> Int {
        let start = startOfMonth(for: baseDate)
        let weekday = calendar.component(.weekday, from: start)
        return ((weekday + 7) - calendar.firstWeekday) % 7
    }
    
    static func stripTime(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func monthTitle(for baseDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: baseDate)
    }
    
    static func changeMonth(_ baseDate: Date, by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: baseDate) ?? baseDate
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

struct OverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return OverviewView()
            .environment(\.managedObjectContext, context)
    }
}