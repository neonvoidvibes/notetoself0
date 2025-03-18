import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var moc
    @AppStorage("didCompleteOnboarding") var didCompleteOnboarding: Bool = false
    
    var body: some View {
        UIStyles.CustomZStack {
            // A vertical stack for the onboarding text & button
            UIStyles.CustomVStack(alignment: .center, spacing: 24) {
                
                Text("Note to Self")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                
                Text("Capture your day in under 30 seconds.\nNo sign-ups, no hassle, just quick reflections.")
                    .font(UIStyles.bodyFont)
                    .foregroundColor(UIStyles.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // Mark onboarding done:
                    didCompleteOnboarding = true
                }) {
                    Text("Get Started")
                }
                .buttonStyle(UIStyles.PrimaryButtonStyle())
                .padding(.top, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
