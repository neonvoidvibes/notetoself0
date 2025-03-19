import SwiftUI

struct EntryAccordionView: View {
    var entry: JournalEntryEntity
    var isExpanded: Bool

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
                            .frame(width: 12, height: 12)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            if isExpanded, let text = entry.text, !text.isEmpty {
                Text(text)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                if let timestamp = entry.timestamp {
                    Text(timestamp, style: .date)
                        .font(UIStyles.smallLabelFont)
                        .foregroundColor(.white)
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
        sampleEntry.timestamp = Date()

        return EntryAccordionView(entry: sampleEntry, isExpanded: false)
            .previewLayout(.sizeThatFits)
    }
}