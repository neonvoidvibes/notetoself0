import SwiftUI
import CoreData

struct MainJournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    // Only one accordion entry expanded at a time.
    @State private var expandedEntry: NSManagedObjectID? = nil
    // State for showing insights toggle
    @State private var showInsights = false
    // State to show the new entry sheet modal
    @State private var showNewEntrySheet = false
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                // Reduced top spacing
                Spacer().frame(height: 20)
                
                // Main title with reduced bottom spacing
                Text("Note to Self")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.bottom, 20)
                
                // "+ Add" button: when tapped, present the new entry sheet modally.
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showNewEntrySheet = true
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
                
                // The list of entries in a scroll view.
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
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
                        .padding(.bottom, 20) // Extra space between entries and chart area
                    }
                }
                
                // Add extra space above the chart header.
                Spacer().frame(height: 30)
                
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
                .padding(.leading, UIStyles.globalHorizontalPadding) // Aligned with other elements
                
                // Chart area (height reduced to 180)
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
        // Present the new entry sheet modally (using default iOS sheet style)
        .sheet(isPresented: $showNewEntrySheet) {
            NewEntrySheet()
        }
    }
}

struct EntryAccordionView: View {
    var entry: JournalEntryEntity
    var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary row remains fixed.
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
                // Expanded content: full text in a scroll view with a max height.
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
