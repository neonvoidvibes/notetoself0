import SwiftUI

/// Global, custom UI definitions that replace standard iOS aesthetics.
/// We define custom stacks, margins, fonts, and color palettes here.
struct UIStyles {
    // MARK: - Colors
    static let appBackground = Color("AppBackground") // define in Assets (dark charcoal)
    static let cardBackground = Color("CardBackground") // slightly lighter charcoal
    static let accentColor = Color("AccentColor") // pick a custom bright color
    static let textColor = Color("TextColor") // near-white
    
    // MARK: - Layout Constants
    static let globalHorizontalPadding: CGFloat = 20
    static let globalVerticalPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    
    // MARK: - Typography
    static let headingFont = Font.system(size: 26, weight: .bold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let smallLabelFont = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // MARK: - Custom Containers
    
    /// Custom "ZStack" with global margins and background color
    struct CustomZStack<Content: View>: View {
        let content: () -> Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                UIStyles.appBackground
                    .edgesIgnoringSafeArea(.all)
                content()
                    // We apply global margins to separate from screen edges
                    .padding(.horizontal, UIStyles.globalHorizontalPadding)
                    .padding(.vertical, UIStyles.globalVerticalPadding)
            }
        }
    }
    
    /// Custom "VStack" with fixed spacing & alignment
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
            // Optional: we can apply a small top/bottom margin
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
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    // A wrapper for using `PrimaryButtonStyle` more directly
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
            // Optional drop shadow for contrast
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}
