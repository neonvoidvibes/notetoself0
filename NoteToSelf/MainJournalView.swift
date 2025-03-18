import SwiftUI
import CoreData

struct MainJournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    // Use single expanded entry ID
    @State private var expandedEntry: NSManagedObjectID? = nil
    // State for showing insights toggle (and new row entry)
    @State private var showInsights = false
    // State for inline new entry row
    @State private var isAddingEntry = false
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: UIStyles.headingFontSize)
                Text("Note to Self")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.bottom, UIStyles.headingFontSize)
                
                // "+ Add" button: when tapped, show new entry row inline at the top
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            isAddingEntry = true
                        }
                    } label: {
                        Text("+ Add")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(UIStyles.accentColor)
                            .cornerRadius(UIStyles.defaultCornerRadius)
                    }
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if isAddingEntry {
                                NewEntryRow(isPresented: $isAddingEntry)
                                    .id("newEntry")
                            }
                            ForEach(entries) { entry in
                                EntryAccordionView(entry: entry, isExpanded: expandedEntry == entry.objectID)
                                    .id(entry.objectID)
                                    .onTapGesture {
                                        withAnimation {
                                            if expandedEntry == entry.objectID {
                                                expandedEntry = nil
                                            } else {
                                                expandedEntry = entry.objectID
                                                // Scroll the expanded entry into view
                                                proxy.scrollTo(entry.objectID, anchor: .bottom)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 20) // extra space between entries and chart area
                    }
                }
                
                // Chart header: "Notes", "Insights", and "Streak"
                HStack(spacing: 20) {
                    Button(action: { showInsights = false }) {
                        Text("Notes")
                            .font(.custom("Menlo", size: 20))
                            .foregroundColor(showInsights ? Color.gray : UIStyles.accentColor)
                    }
                    Button(action: { showInsights = true }) {
                        Text("Insights")
                            .font(.custom("Menlo", size: 20))
                            .foregroundColor(showInsights ? UIStyles.accentColor : Color.gray)
                    }
                    Text("Streak")
                        .font(.custom("Menlo", size: 20))
                        .foregroundColor(Color.gray)
                }
                .padding(.leading, UIStyles.globalHorizontalPadding)
                
                // Chart area: reduce height to 180
                if showInsights {
                    VStack {
                        Text("Insights coming soon")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(UIStyles.textColor)
                        Spacer()
                    }
                    .frame(height: 180)
                } else {
                    MoodChartView(entries: entries)
                        .frame(height: 180)
                }
                
                Spacer()
            }
        }
    }
}

struct EntryAccordionView: View {
    var entry: JournalEntryEntity
    var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary row remains fixed
            HStack {
                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Spacer()
                if let mood = entry.mood, !mood.isEmpty,
                   let moodColor = UIStyles.moodColors[mood] {
                    Circle()
                        .fill(moodColor)
                        .frame(width: 12, height: 12)
                }
            }
            if isExpanded, let text = entry.text, !text.isEmpty {
                // Expanded content: full text inside a scroll view with max height
                ScrollView {
                    Text(text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                }
                .frame(maxHeight: 150)
                
                if let timestamp = entry.timestamp {
                    Text(timestamp, style: .date)
                        .font(UIStyles.smallLabelFont)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isExpanded ? Color(hex: "#111111") : UIStyles.entryBackground)
        .cornerRadius(UIStyles.defaultCornerRadius)
        .animation(.easeInOut, value: isExpanded)
    }
}