import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedMood: String
    @Binding var showOverlay: Bool
    
    let moods = ["Happy", "Excited", "Neutral", "Sad", "Stressed"]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var showIntensitySelector = false
    @State private var moodForIntensity: String = ""
    
    var body: some View {
        ZStack {
            // Dimming background
            UIStyles.tertiaryBackground
                .ignoresSafeArea()
                .onTapGesture {
                    showOverlay = false
                }
            
            // Modal container with shadow, limited to 3 rows height
            ScrollView {
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
                }
                .padding(16)
            }
            .frame(maxWidth: 300, maxHeight: 240)
            .background(Color(hex: "#000000"))
            .cornerRadius(UIStyles.defaultCornerRadius)
            .shadow(radius: 10)
            
            if showIntensitySelector {
                // Wrap intensity modal in a container that allows tap-outside to dismiss intensity modal only.
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showIntensitySelector = false
                        }
                    MoodIntensitySelectorView(mood: moodForIntensity) { opacity in
                        selectedMood = "\(moodForIntensity)|\(opacity)"
                        showIntensitySelector = false
                        showOverlay = false
                    }
                    .transition(.scale)
                }
            }
        }
    }
}

struct MoodSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulWrapper("Neutral") { binding in
            MoodSelectorView(selectedMood: binding, showOverlay: .constant(true))
        }
    }
}

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