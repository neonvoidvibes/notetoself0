import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(spacing: 0) {
                TabBarView(selectedTab: $selectedTab)
                    .frame(height: 50)
                ZStack {
                    switch selectedTab {
                    case .overview:
                        OverviewView()
                    case .notes:
                        NotesView()
                    case .insights:
                        InsightsView()
                    case .chat:
                        ChatView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct MainTabbedView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabbedView()
    }
}