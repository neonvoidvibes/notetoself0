import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedMood: String
    @Binding var showOverlay: Bool
    
    // Mood presets
    let moods = ["Happy", "Excited", "Neutral", "Sad", "Stressed"]
    
    // Use 3 columns grid layout, centered
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // State for intensity selection modal
    @State private var showIntensitySelector = false
    @State private var moodForIntensity: String = ""
    
    var body: some View {
        ZStack {
            // Background for modal: full opacity using #000000
            Color(hex: "#000000")
                .frame(maxWidth: 300, maxHeight: 400)
                .cornerRadius(UIStyles.defaultCornerRadius)
                .shadow(radius: 10)
                .onTapGesture {
                    // Tapping outside does not dismiss this modal (handled in overlay container)
                }
            
            VStack(spacing: 20) {
                Text("Select your mood")
                    .font(UIStyles.smallLabelFont)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: columns, alignment: .center, spacing: 24) {
                    ForEach(moods, id: \.self) { mood in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(UIStyles.moodColors[mood] ?? Color.gray)
                                .frame(width: 28, height: 28)
                                .onTapGesture {
                                    if mood == "Neutral" {
                                        selectedMood = mood
                                        showOverlay = false
                                    } else {
                                        moodForIntensity = mood
                                        showIntensitySelector = true
                                    }
                                }
                            
                            Text(mood)
                                .font(UIStyles.smallLabelFont)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            
            // Intensity selection overlay presented within this modal
            if showIntensitySelector {
                MoodIntensitySelectorView(mood: moodForIntensity) { intensity in
                    // Set the selected mood with intensity information.
                    selectedMood = "\(moodForIntensity) (Intensity \(intensity))"
                    showIntensitySelector = false
                    showOverlay = false
                }
                .transition(.scale)
            }
        }
        .frame(maxWidth: 300, maxHeight: 400)
    }
}

struct MoodSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulWrapper("Neutral") { binding in
            MoodSelectorView(selectedMood: binding, showOverlay: .constant(true))
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