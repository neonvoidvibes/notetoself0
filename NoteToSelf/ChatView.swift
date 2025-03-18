import SwiftUI

struct ChatView: View {
    var body: some View {
        UIStyles.CustomZStack {
            Text("Chat")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)
            
            Spacer().frame(height: 20)
            
            Text("Chat view placeholder.")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}