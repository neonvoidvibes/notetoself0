import SwiftUI

struct NewEntrySheet: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var selectedMood: String = ""
    
    // Some simple moods for demonstration
    let moodOptions = ["Happy", "Neutral", "Sad", "Stressed", "Excited"]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Quick Entry")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                
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
                                    .foregroundColor(selectedMood == mood ? .white : UIStyles.textColor)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // TextEditor with placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(UIStyles.textColor)
                        .frame(height: 120)
                        .padding(8)
                        .background(UIStyles.cardBackground)
                        .cornerRadius(12)
                    
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
            .background(UIStyles.appBackground.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(UIStyles.accentColor)
                }
            }
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