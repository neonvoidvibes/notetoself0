import SwiftUI

// MARK: - Custom Button Styles (Top-level)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        Group {
            configuration.label
                .font(UIStyles.bodyFont)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(UIStyles.accentColor)
                .cornerRadius(UIStyles.defaultCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
}

struct FullWidthSaveButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        Group {
            configuration.label
                .font(UIStyles.bodyFont)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(UIStyles.accentColor)
                .cornerRadius(UIStyles.saveButtonCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
}

// MARK: - UIStyles: Centralized UI Configuration

struct UIStyles {
    
    // MARK: - Colors
    static let appBackground = Color(hex: "#000000")
    static let cardBackground = Color("CardBackground")
    static let accentColor = Color(hex: "#FFFF00")
    static let secondaryAccentColor = Color(hex: "#989898")
    static let textColor = Color("TextColor")
    static let offWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let entryBackground = Color(hex: "#0A0A0A")
    static let secondaryBackground = Color(hex: "#111111")
    static let tertiaryBackground = Color(hex: "#313131")
    static let quaternaryBackground = Color(hex: "#555555")
    
    // Mood colors dictionary for mood tracking
    static let moodColors: [String: Color] = [
        "Happy": Color(red: 1.0, green: 0.84, blue: 0.0),
        "Neutral": Color.gray,
        "Sad": Color.blue,
        "Stressed": Color(red: 0.8, green: 0.0, blue: 0.0),
        "Excited": Color.orange
    ]
    
    // MARK: - Chat UI Colors and Styles
    static let chatBackground = Color(hex: "#000000")
    static let chatInputContainerBackground = Color(hex: "#313131")
    static let chatFont = Font.custom("Menlo", size: 16)
    static let userMessageBubbleColor = offWhite
    static let assistantMessageBubbleColor = Color(hex: "#555555")
    
    // MARK: - Layout Constants
    static let globalHorizontalPadding: CGFloat = 20
    static let globalVerticalPadding: CGFloat = 16
    static let topSpacing: CGFloat = 80
    
    // MARK: - Typography
    static let headingFont = Font.custom("Menlo", size: 36)
    static let bodyFont = Font.custom("Menlo", size: 16)
    static let smallLabelFont = Font.custom("Menlo", size: 14)
    static let tinyHeadlineFont = Font.custom("Menlo", size: 12)
    
    // MARK: - Corners & Radii
    static let defaultCornerRadius: CGFloat = 12
    static let saveButtonCornerRadius: CGFloat = 30
    static let chatInputContainerCornerRadius: CGFloat = 12
    
    // MARK: - Exposed Button Styles
    static var fullWidthSaveButtonStyle: FullWidthSaveButtonStyle { FullWidthSaveButtonStyle() }
    
    // MARK: - Chat Bubble Shape
    struct ChatBubbleShape: Shape {
        var isUser: Bool
        func path(in rect: CGRect) -> Path {
            let path: UIBezierPath
            if isUser {
                path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight, .bottomLeft],
                                    cornerRadii: CGSize(width: defaultCornerRadius, height: defaultCornerRadius))
            } else {
                path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight, .bottomRight],
                                    cornerRadii: CGSize(width: defaultCornerRadius, height: defaultCornerRadius))
            }
            return Path(path.cgPath)
        }
    }
    
    // MARK: - Assistant Loading Indicator
    static var assistantLoadingIndicator: some View {
        Circle()
            .fill(offWhite)
            .frame(width: 20, height: 20)
            .modifier(BreathingAnimation())
    }
    
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
}

// MARK: - Bottom Sheet Style Modifier and Extension
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
        self.modifier(BottomSheetStyleModifier())
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
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

// MARK: - Breathing Animation for Loading Indicator
struct BreathingAnimation: ViewModifier {
    @State private var scale: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(2.0 - scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.5
                }
            }
    }
}

// MARK: - String Extension for Mood Utilities
extension String {
    func baseMood() -> String {
        return self.components(separatedBy: "|").first ?? self
    }
    
    func moodOpacity() -> CGFloat {
        if let lastComponent = self.components(separatedBy: "|").last,
           let opacity = Double(lastComponent) {
            return CGFloat(opacity)
        }
        return 1.0
    }
}