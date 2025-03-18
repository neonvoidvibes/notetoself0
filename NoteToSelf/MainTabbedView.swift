import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    // States for side menus
    @State private var showMainMenu = false
    @State private var showSettingsMenu = false
    
    // Matched geometry namespace for animating icons
    @Namespace private var menuIconNamespace
    
    // Global horizontal padding for menu icons in menu views
    private let globalMenuIconHorizontalPadding: CGFloat = 20
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MAIN CONTENT: This content is pushed right or left when menus open.
                ZStack {
                    VStack(spacing: 0) {
                        // TOP BAR
                        HStack {
                            // Left menu icon in top bar
                            if !showMainMenu {
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showSettingsMenu { showSettingsMenu = false }
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(20) // increased tap area
                            }
                            
                            Spacer()
                            
                            // Right settings icon in top bar
                            if !showSettingsMenu {
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showMainMenu { showMainMenu = false }
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(20) // increased tap area
                            }
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 20)
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
                    .background(UIStyles.appBackground)
                    .cornerRadius((showMainMenu || showSettingsMenu) ? 20 : 0)
                }
                .offset(x: showMainMenu ? geo.size.width * 0.75 : (showSettingsMenu ? -geo.size.width * 0.75 : 0))
                .animation(.easeInOut, value: showMainMenu || showSettingsMenu)
                .edgesIgnoringSafeArea(.all)
                
                // TAP-OUTSIDE OVERLAY to close menus
                if showMainMenu || showSettingsMenu {
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showMainMenu = false
                                showSettingsMenu = false
                            }
                        }
                }
                
                // LEFT SIDE MAIN MENU
                if showMainMenu {
                    HStack(spacing: 0) {
                        VStack {
                            HStack {
                                Spacer()
                                // Right-adjusted icon in left menu view
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(.horizontal, globalMenuIconHorizontalPadding)
                            }
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.75)
                        .background(UIStyles.secondaryBackground)
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                
                // RIGHT SIDE SETTINGS MENU
                if showSettingsMenu {
                    HStack(spacing: 0) {
                        Spacer()
                        VStack {
                            HStack {
                                // Left-adjusted icon in right menu view
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(.horizontal, globalMenuIconHorizontalPadding)
                                Spacer()
                            }
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.75)
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
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w * 0.8 : w, height: lineHeight)
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
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: circleDiameter, height: circleDiameter)
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: circleDiameter, height: circleDiameter)
                }
                .offset(x: isOpen ? 2 : (width - circleDiameter - 2), y: -circleDiameter/2)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                    .offset(y: spacing)
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