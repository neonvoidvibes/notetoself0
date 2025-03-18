import SwiftUI

struct UIStyles {
    // MARK: - Colors
    static let appBackground = Color(hex: "#222530")
    static let cardBackground = Color("CardBackground") // defined in Assets, can be adjusted if needed
    static let accentColor = Color("AccentColor")
    static let textColor = Color("TextColor")
    
    // Proper colors for moods
    static let moodColors: [String: Color] = [
        "Happy": Color(red: 1.0, green: 0.84, blue: 0.0),      // Gold
        "Neutral": Color.gray,
        "Sad": Color.blue,
        "Stressed": Color(red: 0.8, green: 0.0, blue: 0.0),      // Dark Red
        "Excited": Color.orange
    ]
    
    // MARK: - Layout Constants
    static let globalHorizontalPadding: CGFloat = 20
    static let globalVerticalPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20 // Increased rounding
    
    // MARK: - Typography
    static let headingFont = Font.system(size: 26, weight: .bold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let smallLabelFont = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // MARK: - Custom Containers
    
    /// Custom ZStack with global margins and background color
    struct CustomZStack<Content: View>: View {
        let content: () -> Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                appBackground
                    .edgesIgnoringSafeArea(.all)
                content()
                    .padding(.horizontal, globalHorizontalPadding)
                    .padding(.vertical, globalVerticalPadding)
            }
        }
    }
    
    /// Custom VStack with fixed spacing & alignment
    struct CustomVStack<Content: View>: View {
        let alignment: HorizontalAlignment
        let spacing: CGFloat
        let content: () -> Content
        
        init(alignment: HorizontalAlignment = .leading,
             spacing: CGFloat = 12,
             @ViewBuilder content: @escaping () -> Content) {
            self.alignment = alignment
            self.spacing = spacing
            self.content = content
        }
        
        var body: some View {
            VStack(alignment: alignment, spacing: spacing) {
                content()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Custom Button Styles
    
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(UIStyles.bodyFont)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(UIStyles.accentColor)
                .cornerRadius(12) // Increased rounding on buttons
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    static func primaryButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {}) {
            label()
        }.buttonStyle(PrimaryButtonStyle())
    }
    
    // MARK: - Card Container
    struct Card<Content: View>: View {
        let content: () -> Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        
        var body: some View {
            VStack(spacing: 8) {
                content()
            }
            .padding()
            .background(UIStyles.cardBackground)
            .cornerRadius(UIStyles.cardCornerRadius)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}

extension Color {
    // Helper initializer for hex color codes.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}