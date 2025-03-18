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
                    // Force input field background to black using custom setting
                    .background(Color.black)
                    .cornerRadius(UIStyles.defaultCornerRadius)
                // "Mood" button with black text on white background
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
        // Outer container: enforce black background, remove any inner borders and shadows
        .background(Color.black)
        .cornerRadius(UIStyles.defaultCornerRadius)
        .overlay(
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

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct NewEntryRow_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return NewEntryRow(isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
            .previewLayout(.sizeThatFits)
    }
}