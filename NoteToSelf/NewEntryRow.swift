import SwiftUI
import CoreData

struct NewEntryRow: View {
    @Environment(\.managedObjectContext) private var moc
    // Binding to control presentation from MainJournalView
    @Binding var isPresented: Bool
    
    @State private var text: String = ""
    @State private var selectedMood: String = ""
    @State private var showMoodSelector: Bool = false
    
    // Example mood options
    let moodOptions = ["Happy", "Neutral", "Sad", "Stressed", "Excited"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Editable row mimicking a submitted entry
            HStack {
                TextEditor(text: $text)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .frame(minHeight: 40, maxHeight: 80)
                    .padding(4)
                    .background(Color(hex: "#111111"))
                    .cornerRadius(UIStyles.defaultCornerRadius)
                // "Mood" button replaces mood dot
                Button(action: {
                    withAnimation {
                        showMoodSelector.toggle()
                    }
                }) {
                    Text(selectedMood.isEmpty ? "Mood" : selectedMood)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(UIStyles.defaultCornerRadius)
                }
            }
            // Save and Cancel buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    withAnimation {
                        isPresented = false
                    }
                }
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.accentColor)
                Button("Save") {
                    saveEntry()
                }
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.accentColor)
            }
        }
        .padding()
        .background(Color(hex: "#111111"))
        .cornerRadius(UIStyles.defaultCornerRadius)
        .overlay(
            // Mood selector overlay
            Group {
                if showMoodSelector {
                    VStack(spacing: 12) {
                        ForEach(moodOptions, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                                showMoodSelector = false
                            }) {
                                Text(mood)
                                    .font(UIStyles.bodyFont)
                                    .foregroundColor(Color.black)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(UIStyles.defaultCornerRadius)
                            }
                        }
                    }
                    .padding()
                    .background(BlurView(style: .systemMaterial))
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .shadow(radius: 8)
                    .padding(40)
                }
            }
        )
    }
    
    private func saveEntry() {
        let newItem = JournalEntryEntity(context: moc)
        newItem.timestamp = Date()
        newItem.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        newItem.mood = selectedMood
        
        do {
            try moc.save()
            withAnimation {
                isPresented = false
            }
        } catch {
            print("Failed to save new entry: \(error)")
        }
    }
}

// A simple UIViewRepresentable wrapper for a blur effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct NewEntryRow_Previews: PreviewProvider {
    static var previews: some View {
        // For preview purposes, create an in-memory managed object context
        let context = PersistenceController.preview.container.viewContext
        return NewEntryRow(isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
            .previewLayout(.sizeThatFits)
    }
}