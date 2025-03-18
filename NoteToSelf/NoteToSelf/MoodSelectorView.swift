import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedMood: String
    @Environment(\.dismiss) private var dismiss
    
    // Our mood presets from UIStyles
    let moods = ["Happy", "Excited", "Neutral", "Sad", "Stressed"]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            UIStyles.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select Your Mood")
                    .font(UIStyles.headingFont)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: columns, alignment: .center, spacing: 24) {
                    ForEach(moods, id: \.self) { mood in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(UIStyles.moodColors[mood] ?? Color.gray)
                                .frame(width: 40, height: 40)
                                .onTapGesture {
                                    selectedMood = mood
                                    dismiss()
                                }
                            
                            Text(mood)
                                .font(UIStyles.bodyFont)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

struct MoodSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulWrapper("Neutral") { binding in
            MoodSelectorView(selectedMood: binding)
        }
    }
}

// Helper for single-binding previews
struct StatefulWrapper<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content
    
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
}