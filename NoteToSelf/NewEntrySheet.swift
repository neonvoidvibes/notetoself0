import SwiftUI

struct NewEntrySheet: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var selectedMood: String = ""
    
    let moodOptions = ["Happy", "Neutral", "Sad", "Stressed", "Excited"]
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            // Overlay card with blur and shadow
            VStack(alignment: .leading, spacing: 16) {
                // Cancel button at the top
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(UIStyles.bodyFont)
                    .foregroundColor(UIStyles.accentColor)
                    Spacer()
                }
                // Title
                Text("Add Note")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.bottom, UIStyles.headingFontSize / 2)
                
                // Mood picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(moodOptions, id: \.self) { mood in
                            Button {
                                selectedMood = mood
                            } label: {
                                Text(mood)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedMood == mood ? UIStyles.moodColors[mood] ?? UIStyles.accentColor : UIStyles.cardBackground)
                                    .foregroundColor(selectedMood == mood ? Color.black : UIStyles.textColor)
                                    .cornerRadius(UIStyles.defaultCornerRadius)
                            }
                        }
                    }
                }
                // TextEditor with placeholder for note submission
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(Color.white)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(hex: "#111111"))
                        .cornerRadius(UIStyles.defaultCornerRadius)
                    if text.isEmpty {
                        Text("Write a short note...")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(UIStyles.textColor.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                }
                // Save button aligned to the right
                HStack {
                    Spacer()
                    Button("Save") {
                        saveEntry()
                    }
                    .buttonStyle(UIStyles.PrimaryButtonStyle())
                    .disabled(selectedMood.isEmpty)
                }
            }
            .padding()
            // Use ultra thin material for blur effect and add shadow
            .background(.ultraThinMaterial)
            .cornerRadius(UIStyles.defaultCornerRadius)
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
            // Expanded width and reduced vertical padding
            .padding(.horizontal, 20)
            .frame(maxHeight: 300)
        }
    }
    
    private func saveEntry() {
        let newItem = JournalEntryEntity(context: moc)
        newItem.timestamp = Date()
        newItem.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        newItem.mood = selectedMood
        
        do {
            try moc.save()
            dismiss()
        } catch {
            print("Failed to save new entry: \(error)")
        }
    }
}