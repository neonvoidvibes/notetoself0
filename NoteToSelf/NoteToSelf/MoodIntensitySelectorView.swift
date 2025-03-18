import SwiftUI

struct MoodIntensitySelectorView: View {
    var mood: String
    // Closure that returns the chosen intensity level (1, 2, or 3)
    var onSelectIntensity: (Int) -> Void
    
    // Opacities in reverse order: left: lightest, middle: medium, right: full opacity
    private let intensities: [CGFloat] = [0.3, 0.6, 1.0]
    
    var body: some View {
        ZStack {
            // Background overlay for intensity modal, tap outside dismisses intensity modal (but not the parent MoodSelectorView)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Do nothing here; gesture handled in container of this view to dismiss intensity modal
                }
            
            VStack(spacing: 16) {
                Text("Intensity")
                    .font(UIStyles.smallLabelFont)
                    .foregroundColor(.white)
                
                HStack(spacing: 24) {
                    ForEach(0..<intensities.count, id: \.self) { index in
                        Circle()
                            .fill(UIStyles.moodColors[mood] ?? Color.gray)
                            .opacity(intensities[index])
                            .frame(width: 28, height: 28)
                            .onTapGesture {
                                onSelectIntensity(index + 1)
                            }
                    }
                }
            }
            .padding()
            .background(Color(hex: "#000000"))
            .cornerRadius(UIStyles.defaultCornerRadius)
            .frame(maxWidth: 200)
            .shadow(radius: 10)
        }
    }
}

struct MoodIntensitySelectorView_Previews: PreviewProvider {
    static var previews: some View {
        MoodIntensitySelectorView(mood: "Sad") { intensity in
            print("Selected intensity: \(intensity)")
        }
    }
}