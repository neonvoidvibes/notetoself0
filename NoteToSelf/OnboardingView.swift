import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var moc
    @State private var showMainView: Bool = false

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
                    // On tapping Get Started, present the main journal view
                    showMainView = true
                }) {
                    Text("Get Started")
                }
                .buttonStyle(UIStyles.PrimaryButtonStyle())
                .padding(.top, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainJournalView()
                .environment(\.managedObjectContext, moc)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}