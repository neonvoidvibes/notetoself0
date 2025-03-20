import SwiftUI

struct EntryAccordionView: View {
    var entry: JournalEntryEntity
    var isExpanded: Bool

    // Lock logic: if older than 24 hours, we consider it locked
    private var isLocked: Bool {
        guard let timestamp = entry.timestamp else { return false }
        let diff = Date().timeIntervalSince(timestamp)
        return diff > 86400 // 24 hours in seconds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let mood = entry.mood, !mood.isEmpty {
                    let base = mood.baseMood()
                    let opacity = mood.moodOpacity()
                    if let color = UIStyles.moodColors[base] {
                        Circle()
                            .fill(color.opacity(opacity))
                            .frame(width: 18, height: 18)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 6)
                    }
                }
            }
            // Expanded content
            if isExpanded {
                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.white)
                }
                if let timestamp = entry.timestamp {
                    // Show date and locked label if needed
                    HStack {
                        Text(timestamp, style: .date)
                            .font(UIStyles.smallLabelFont)
                            .foregroundColor(.white)
                        if isLocked {
                            Text("Locked")
                                .font(UIStyles.smallLabelFont)
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isExpanded ? nil : 40)
        .background(Color.clear)
    }
}

struct EntryAccordionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleEntry = JournalEntryEntity(context: context)
        sampleEntry.text = "Sample Entry"
        sampleEntry.mood = "Happy"
        sampleEntry.timestamp = Date().addingTimeInterval(-90000) // older than 24h

        return Group {
            EntryAccordionView(entry: sampleEntry, isExpanded: false)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Collapsed, locked")
            EntryAccordionView(entry: sampleEntry, isExpanded: true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Expanded, locked")
        }
        .background(Color.black)
    }
}