import SwiftUI

struct UIStyles {
    // MARK: - Colors
    static let appBackground = Color(hex: "#000000")   // Full black background
    static let cardBackground = Color("CardBackground")
    static let accentColor = Color(hex: "#FFFF00")
    static let secondaryAccentColor = Color(hex: "#989898")
    static let textColor = Color("TextColor")
    static let offWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let entryBackground = Color(hex: "#0A0A0A")
    
    // Secondary background as needed
    static let secondaryBackground = Color(hex: "#111111")
    
    // Proper colors for moods
    static let moodColors: [String: Color] = [
        "Happy": Color(red: 1.0, green: 0.84, blue: 0.0),
        "Neutral": Color.gray,
        "Sad": Color.blue,
        "Stressed": Color(red: 0.8, green: 0.0, blue: 0.0),
        "Excited": Color.orange
    ]
    
    // MARK: - Layout Constants
    static let globalHorizontalPadding: CGFloat = 20
    static let globalVerticalPadding: CGFloat = 16
    static let topSpacing: CGFloat = 80  // This value is now used exclusively in MainTabbedView for the top menu
    
    // MARK: - Typography
    static let headingFont = Font.custom("Menlo", size: 48)
    static let headingFontSize: CGFloat = 48
    static let bodyFont = Font.custom("Menlo", size: 16)
    static let smallLabelFont = Font.custom("Menlo", size: 14)
    
    // MARK: - Custom Containers
    
    struct CustomZStack<Content: View>: View {
        let content: () -> Content
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    appBackground.ignoresSafeArea()
                    VStack(alignment: .leading, spacing: 0) {
                        // Use only the safe area inset, no extra topSpacing added here.
                        Spacer().frame(height: geo.safeAreaInsets.top)
                        content()
                    }
                    .padding(.horizontal, globalHorizontalPadding)
                    .padding(.bottom, globalVerticalPadding)
                }
            }
        }
    }
    
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
                .foregroundColor(Color.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(UIStyles.accentColor)
                .cornerRadius(UIStyles.defaultCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    static func primaryButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {}) {
            label()
        }
        .buttonStyle(PrimaryButtonStyle())
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
            .background(cardBackground)
            .cornerRadius(defaultCornerRadius)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
    
    static let defaultCornerRadius: CGFloat = 12
}

extension Color {
    // Helper initializer for hex color codes.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}