import SwiftUI

struct OverviewView: View {
    var body: some View {
        UIStyles.CustomZStack {
            Text("Overview")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)
            
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