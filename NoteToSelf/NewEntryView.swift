import SwiftUI

struct NewEntryView: View {
    // Bindings from parent so text + mood persist if user cancels (sheet is dismissed)
    @Binding var noteText: String
    @Binding var selectedMood: String
    
    // Closure to perform save action
    var onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // For presenting mood selector
    @State private var showMoodSelector = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background color (no blur/transparency)
            UIStyles.secondaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                // Top bar with a plus sign inside a round button (semi-transparent)
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Dismiss without saving, text is preserved in the parent's state
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 16)
                
                // Title or prompt (optional)
                Text("Add Note")
                    .font(UIStyles.headingFont)
                    .foregroundColor(.white)
                
                // Input editor
                TextEditor(text: $noteText)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .padding(12)
                    .frame(minHeight: 100, maxHeight: 150)
                    .background(Color(hex: "#111111"))
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                
                // Mood picker row
                HStack(spacing: 8) {
                    // Mood circle
                    Circle()
                        .fill(UIStyles.moodColors[selectedMood] ?? Color.gray)
                        .frame(width: 28, height: 28)
                        .onTapGesture {
                            showMoodSelector = true
                        }
                    
                    Text("Select mood")
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.white)
                        .onTapGesture {
                            showMoodSelector = true
                        }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Bottom "Save" button
                HStack {
                    Spacer()
                    Button(action: {
                        // Perform parent's save logic, then dismiss
                        onSave()
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .buttonStyle(UIStyles.PrimaryButtonStyle())
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
                
            } // VStack
        }
        // Apply bottom sheet style with large corners
        .applyBottomSheetStyle()
        // Present mood selector
        .sheet(isPresented: $showMoodSelector) {
            MoodSelectorView(selectedMood: $selectedMood)
                .applyBottomSheetStyle()
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        // Example usage with local state using two separate bindings
        StatefulPreviewWrapper(("", "Neutral")) { noteBinding, moodBinding in
            NewEntryView(
                noteText: noteBinding,
                selectedMood: moodBinding
            ) {
                print("Saving...")
            }
        }
    }
}

// Helper for SwiftUI previews to bind to local states
struct StatefulPreviewWrapper<Value1, Value2, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    let content: (Binding<Value1>, Binding<Value2>) -> Content
    
    init(_ initialValue: (Value1, Value2), @ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>) -> Content) {
        _value1 = State(initialValue: initialValue.0)
        _value2 = State(initialValue: initialValue.1)
        self.content = content
    }
    
    var body: some View {
        content($value1, $value2)
    }
}