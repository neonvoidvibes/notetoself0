import SwiftUI

struct OnboardingView: View {
    @AppStorage("HasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var currentStep: Int = 0

    private let totalSteps = 3

    var body: some View {
        ZStack {
            // Background style
            UIStyles.appBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                // Skip button, top-right
                HStack {
                    Spacer()
                    Button(action: {
                        // Mark onboarding as done
                        hasSeenOnboarding = true
                    }) {
                        Text("Skip")
                            .foregroundColor(UIStyles.accentColor)
                            .font(UIStyles.bodyFont)
                            .padding(.trailing, 16)
                    }
                }
                .frame(height: 40)
                .padding(.top, 16)

                Spacer()

                // Main content for each step
                contentForCurrentStep()

                Spacer()

                // Next / Done button
                Button(action: handleNext) {
                    Text(currentStep < (totalSteps - 1) ? "Next" : "Get Started")
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(UIStyles.accentColor)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 16)
        }
    }

    private func contentForCurrentStep() -> some View {
        switch currentStep {
        case 0:
            return AnyView(stepOneView)
        case 1:
            return AnyView(stepTwoView)
        case 2:
            return AnyView(stepThreeView)
        default:
            return AnyView(stepThreeView)
        }
    }

    private var stepOneView: some View {
        VStack(spacing: 16) {
            Text("Welcome to Note to Self")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)
                .multilineTextAlignment(.center)

            Text("Capture your day in under 30 seconds.\nNo sign-ups, no hassle, just quick reflections.")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
    }

    private var stepTwoView: some View {
        VStack(spacing: 16) {
            Text("3 Main Tabs")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)

            Text("1) Journal - Quickly log entries\n2) Insights - View streaks & mood trends\n3) Reflections - Chat with the AI")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
    }

    private var stepThreeView: some View {
        VStack(spacing: 16) {
            Text("Privacy-First & Optional Upgrades")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)

            Text("Everything is stored locally unless you choose to back it up.\nNo login required. If you want advanced insights or premium themes, you can subscribe anytime.")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
    }

    private func handleNext() {
        if currentStep < (totalSteps - 1) {
            currentStep += 1
        } else {
            // Final step: Mark onboarding as done
            hasSeenOnboarding = true
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}