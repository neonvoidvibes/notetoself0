import SwiftUI

struct MainJournalView: View {
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
                if let mood = entry.mood, !mood.isEmpty {
                    let base = mood.baseMood()
                    let opacity = mood.moodOpacity()
                    if let color = UIStyles.moodColors[base] {
                        Circle()
                            .fill(color.opacity(opacity))
                            .frame(width: 12, height: 12)
                    }
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