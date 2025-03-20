import SwiftUI

enum AppTab: CaseIterable {
    case journal
    case insights
    case reflections
    
    var title: String {
        switch self {
        case .journal:     return "Journal"
        case .insights:    return "Insights"
        case .reflections: return "Reflections"
        }
    }
    
    var iconName: String {
        switch self {
        case .journal:     return "book.closed"
        case .insights:    return "chart.bar"
        case .reflections: return "quote.bubble"
        }
    }
}

struct TabBarView: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 40) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(tab == selectedTab ? UIStyles.accentColor : UIStyles.secondaryAccentColor)
                    
                    Text(tab.title)
                        .font(UIStyles.bodyFont)
                        .foregroundColor(tab == selectedTab ? UIStyles.accentColor : UIStyles.secondaryAccentColor)
                }
                .padding(.vertical, 12)
                .onTapGesture {
                    withAnimation {
                        selectedTab = tab
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

struct TabBarView_Previews: PreviewProvider {
    @State static var selectedTab: AppTab = .journal
    static var previews: some View {
        TabBarView(selectedTab: $selectedTab)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(UIStyles.appBackground)
    }
}