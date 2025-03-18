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
    // New tertiary background color for dots
    static let tertiaryBackground = Color(hex: "#313131")
    
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
    static let headingFont = Font.custom("Menlo", size: 36)
    static let headingFontSize: CGFloat = 36
    static let bodyFont = Font.custom("Menlo", size: 16)
    static let smallLabelFont = Font.custom("Menlo", size: 14)
    // New tiny headline font for intensity modal title
    static let tinyHeadlineFont = Font.custom("Menlo", size: 12)
    
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
    
    static func primaryButton<Label: View>(@ViewBuilder label: @escaping () -> Label) -> some View {
        Button(action: {}) {
            label()
        }
        .buttonStyle(PrimaryButtonStyle())
    }
    
    // New full-width Save button style with increased rounded corners
    struct FullWidthSaveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(UIStyles.bodyFont)
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(UIStyles.accentColor)
                .cornerRadius(UIStyles.saveButtonCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    static let saveButtonCornerRadius: CGFloat = 30
    
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

// MARK: - Color Hex Extension
extension Color {
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

// MARK: - Bottom Sheet Style Preset
struct BottomSheetStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.height(420), .large])
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
    }
}

extension View {
    func applyBottomSheetStyle() -> some View {
        modifier(BottomSheetStyleModifier())
    }
}

// MARK: - String Extensions for Mood Parsing
extension String {
    func baseMood() -> String {
        return self.components(separatedBy: "|").first ?? self
    }
    
    func moodOpacity() -> CGFloat {
        if let part = self.components(separatedBy: "|").last, let value = Double(part) {
            return CGFloat(value)
        }
        return 1.0
    }
}