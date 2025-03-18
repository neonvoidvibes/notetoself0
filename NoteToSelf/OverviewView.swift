import SwiftUI

struct OverviewView: View {
    var body: some View {
        UIStyles.CustomVStack {
            // Extra top padding increased to 60 to push the headline further down
            Text("Overview")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)
                .padding(.top, 40)
            
            Spacer().frame(height: 20)
            
            Text("This is the Overview screen (placeholder).")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
        }
    }
}

struct OverviewView_Previews: PreviewProvider {
    static var previews: some View {
        OverviewView()
    }
}