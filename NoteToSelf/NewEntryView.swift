import SwiftUI

struct NewEntryView: View {
    // Bindings from parent so text + mood persist if user cancels (sheet is dismissed)
    @Binding var noteText: String
    @Binding var selectedMood: String
    
    // Closure to perform save action
    var onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // For presenting mood selector overlay
    @State private var showMoodSelector = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background color (no blur/transparency)
            UIStyles.secondaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Top bar with an "x" icon inside a round button (semi-transparent)
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 16)
                
                // Title
                Text("Add Note")
                    .font(UIStyles.headingFont)
                    .foregroundColor(.white)
                
                // Input editor with background color set to #000000
                TextEditor(text: $noteText)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .padding(12)
                    .frame(minHeight: 100, maxHeight: 150)
                    .background(Color(hex: "#000000"))
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                
                // Mood picker row
                HStack(spacing: 8) {
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
                
                // Bottom Save button
                HStack {
                    Spacer()
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .buttonStyle(UIStyles.PrimaryButtonStyle())
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
        }
        // Present MoodSelectorView as an overlay
        .overlay(
            Group {
                if showMoodSelector {
                    MoodSelectorView(selectedMood: $selectedMood, showOverlay: $showMoodSelector)
                        .transition(.opacity)
                }
            }
        )
        .applyBottomSheetStyle()
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
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