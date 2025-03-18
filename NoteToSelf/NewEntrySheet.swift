import SwiftUI

struct NewEntrySheet: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var selectedMood: String = ""
    
    let moodOptions = ["Happy", "Neutral", "Sad", "Stressed", "Excited"]
    
    var body: some View {
        // Using an overlay card style with background blur
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Note")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.bottom, UIStyles.headingFontSize) // Extra padding using defined constant
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
                // TextEditor with placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(Color.white)
                        .frame(height: 120)
                        .padding(8)
                        .background(UIStyles.entryBackground)
                        .cornerRadius(UIStyles.defaultCornerRadius)
                    if text.isEmpty {
                        Text("Write a short note...")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(UIStyles.textColor.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                }
                Spacer()
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
            .background(Color.white.opacity(0.05))
            .cornerRadius(UIStyles.defaultCornerRadius)
            .padding(.horizontal, 40)
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