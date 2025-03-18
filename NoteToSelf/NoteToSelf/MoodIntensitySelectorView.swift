import SwiftUI

struct MoodIntensitySelectorView: View {
    var mood: String
    // Closure returns the chosen opacity value (as CGFloat)
    var onSelectIntensity: (CGFloat) -> Void
    
    // Opacities in reverse order: left: lightest, middle: medium, right: full opacity
    private let intensities: [CGFloat] = [0.3, 0.6, 1.0]
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Intensity modal tap outside is handled by parent; do nothing here.
                }
            VStack(spacing: 16) {
                Text("Intensity")
                    .font(UIStyles.tinyHeadlineFont)
                    .foregroundColor(.white)
                HStack(spacing: 24) {
                    ForEach(0..<intensities.count, id: \.self) { index in
                        Circle()
                            .fill(UIStyles.moodColors[mood] ?? Color.gray)
                            .opacity(intensities[index])
                            .frame(width: 28, height: 28)
                            .onTapGesture {
                                onSelectIntensity(intensities[index])
                            }
                    }
                }
            }
            .padding()
            .background(Color(hex: "#000000"))
            .cornerRadius(UIStyles.defaultCornerRadius)
            .shadow(radius: 10)
            .frame(maxWidth: 200)
        }
    }
}

struct MoodIntensitySelectorView_Previews: PreviewProvider {
    static var previews: some View {
        MoodIntensitySelectorView(mood: "Sad") { opacity in
            print("Selected opacity: \(opacity)")
        }
    }
}