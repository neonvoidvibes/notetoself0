import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    // States for side menus
    @State private var showMainMenu = false
    @State private var showSettingsMenu = false
    
    // Matched geometry namespace for animating icons
    @Namespace private var menuIconNamespace
    
    // Horizontal padding for icons
    private let menuIconHorizontalPadding: CGFloat = UIStyles.globalHorizontalPadding
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MAIN CONTENT
                ZStack {
                    VStack(spacing: 0) {
                        // TOP BAR
                        HStack {
                            // Left menu icon
                            if !showMainMenu {
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showSettingsMenu { showSettingsMenu = false }
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(20)
                            }
                            
                            Spacer()
                            
                            // Right settings icon
                            if !showSettingsMenu {
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showMainMenu { showMainMenu = false }
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(20)
                            }
                        }
                        // Use UIStyles.topSpacing and bottom the same
                        .padding(.top, UIStyles.topSpacing)
                        .padding(.bottom, UIStyles.topSpacing)
                        .padding(.horizontal, 16)
                        
                        // TAB BAR
                        TabBarView(selectedTab: $selectedTab)
                            .frame(height: 50)
                        
                        // SELECTED CONTENT
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
                    // Guarantee full black background
                    .background(UIStyles.appBackground.ignoresSafeArea())
                    .cornerRadius((showMainMenu || showSettingsMenu) ? 20 : 0)
                }
                // Offset main content by 80% if a menu is open
                .offset(x: showMainMenu ? geo.size.width * 0.8 :
                        (showSettingsMenu ? -geo.size.width * 0.8 : 0))
                .animation(.easeInOut, value: showMainMenu || showSettingsMenu)
                .edgesIgnoringSafeArea(.all)
                
                // BLACK OVERLAY for tap-outside
                if showMainMenu || showSettingsMenu {
                    Color.black
                        .opacity(0.4) // visible overlay
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showMainMenu = false
                                showSettingsMenu = false
                            }
                        }
                }
                
                // LEFT SIDE MENU
                if showMainMenu {
                    // Put the left menu above main content so it overlays
                    HStack(spacing: 0) {
                        VStack {
                            HStack {
                                Spacer()
                                // Right-adjusted icon inside the left menu
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            showMainMenu = false
                                        }
                                    }
                                    .padding(.horizontal, menuIconHorizontalPadding)
                            }
                            // Use same topSpacing for top & bottom
                            .padding(.top, UIStyles.topSpacing)
                            .padding(.bottom, UIStyles.topSpacing)
                            Spacer()
                        }
                        // Left menu is 80% wide
                        .frame(width: geo.size.width * 0.8)
                        .background(UIStyles.secondaryBackground)
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                
                // RIGHT SIDE MENU
                if showSettingsMenu {
                    // Put the right menu above main content so it overlays
                    HStack(spacing: 0) {
                        Spacer()
                        VStack {
                            HStack {
                                // Left-adjusted icon inside the right menu
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            showSettingsMenu = false
                                        }
                                    }
                                    .padding(.horizontal, menuIconHorizontalPadding)
                                Spacer()
                            }
                            .padding(.top, UIStyles.topSpacing)
                            .padding(.bottom, UIStyles.topSpacing)
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.8)
                        .background(UIStyles.secondaryBackground)
                        .transition(.move(edge: .trailing))
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
}

// MARK: - Animated Icons

struct AnimatedMenuIcon: View {
    var isOpen: Bool
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lineHeight: CGFloat = 2
            let spacing: CGFloat = 8
            
            ZStack(alignment: .topLeading) {
                // top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w * 0.8 : w, height: lineHeight)
                
                // bottom line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w : w * 0.8, height: lineHeight)
                    .offset(y: spacing)
            }
        }
        .frame(width: 24, height: 8)
        .animation(.easeInOut, value: isOpen)
    }
}

struct AnimatedSettingsIcon: View {
    var isOpen: Bool
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let lineHeight: CGFloat = 2
            let spacing: CGFloat = 8
            let circleDiameter: CGFloat = 8
            
            ZStack(alignment: .topLeading) {
                // top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                
                // top circle
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: circleDiameter, height: circleDiameter)
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: circleDiameter, height: circleDiameter)
                }
                .offset(x: isOpen ? 2 : (width - circleDiameter - 2), y: -circleDiameter/2)
                
                // bottom line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                    .offset(y: spacing)
                
                // bottom circle
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: circleDiameter, height: circleDiameter)
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: circleDiameter, height: circleDiameter)
                }
                .offset(x: isOpen ? (width - circleDiameter - 2) : 2, y: spacing - circleDiameter/2)
            }
        }
        .frame(width: 24, height: 8)
        .animation(.easeInOut, value: isOpen)
    }
}

struct MainTabbedView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabbedView()
    }
}