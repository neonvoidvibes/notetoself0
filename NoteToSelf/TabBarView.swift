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
}

struct TabBarView: View {
    @Binding var selectedTab: AppTab
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var showLeftChevron: Bool = false
    @State private var showRightChevron: Bool = false
    
    let tabSpacing: CGFloat = 40
    let tabPadding: CGFloat = 20
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: tabSpacing) {
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            tabItem(for: tab)
                        }
                    }
                    .padding(.horizontal, tabPadding)
                    .background(
                        GeometryReader { contentGeo in
                            Color.clear
                                .onAppear {
                                    contentWidth = contentGeo.size.width
                                    updateChevronVisibility(containerWidth: geo.size.width)
                                }
                                .onChange(of: contentGeo.size.width) { _, newValue in
                                    contentWidth = newValue
                                    updateChevronVisibility(containerWidth: geo.size.width)
                                }
                        }
                    )
                }
                .mask(edgeFadingMask(containerWidth: geo.size.width))
                
                if showLeftChevron {
                    HStack {
                        Button(action: {
                            withAnimation {
                                scrollOffset = max(scrollOffset - 100, 0)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(UIStyles.secondaryAccentColor)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                }
                
                if showRightChevron {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                let maxOffset = contentWidth - geo.size.width
                                scrollOffset = min(scrollOffset + 100, maxOffset)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(UIStyles.secondaryAccentColor)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .offset(x: -scrollOffset)
            .onChange(of: selectedTab) { _, newTab in
                DispatchQueue.main.async {
                    centerSelected(tab: newTab, containerWidth: geo.size.width)
                }
            }
        }
    }
    
    private func tabItem(for tab: AppTab) -> some View {
        VStack {
            Text(tab.title)
                .font(UIStyles.bodyFont)
                .foregroundColor(tab == selectedTab ? UIStyles.accentColor : UIStyles.secondaryAccentColor)
                .padding(.bottom, 4)
            Rectangle()
                .fill(tab == selectedTab ? UIStyles.accentColor : Color.clear)
                .frame(height: 3)
        }
        .padding(.vertical, 32)
        .onTapGesture {
            withAnimation {
                selectedTab = tab
            }
        }
    }
    
    private func edgeFadingMask(containerWidth: CGFloat) -> LinearGradient {
        let fadeWidth: CGFloat = 20
        let leftStop = scrollOffset > 0 ? fadeWidth / containerWidth : 0
        let rightStop = (scrollOffset + containerWidth < contentWidth) ? 1 - (fadeWidth / containerWidth) : 1
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0), location: 0),
                .init(color: Color.black, location: leftStop),
                .init(color: Color.black, location: rightStop),
                .init(color: Color.black.opacity(0), location: 1)
            ]),
            startPoint: .leading, endPoint: .trailing
        )
    }
    
    private func updateChevronVisibility(containerWidth: CGFloat) {
        let isOverflow = contentWidth > containerWidth
        showLeftChevron = isOverflow && scrollOffset > 0
        showRightChevron = isOverflow && (scrollOffset + containerWidth < contentWidth)
    }
    
    private func centerSelected(tab: AppTab, containerWidth: CGFloat) {
        // We'll just do a simple approach:
        // If user selects the first tab, offset=0
        // If user selects last tab, offset=some max
        // Middle for the middle tab. A more robust approach would measure the position
        switch tab {
        case .journal:
            scrollOffset = 0
        case .insights:
            let approxMid = contentWidth / 2 - containerWidth / 2
            scrollOffset = max(0, min(approxMid, contentWidth - containerWidth))
        case .reflections:
            let maxOffset = max(contentWidth - containerWidth, 0)
            scrollOffset = maxOffset
        }
        updateChevronVisibility(containerWidth: containerWidth)
    }
}

struct TabBarView_Previews: PreviewProvider {
    @State static var selectedTab: AppTab = .journal
    static var previews: some View {
        TabBarView(selectedTab: $selectedTab)
            .frame(height: 50)
    }
}