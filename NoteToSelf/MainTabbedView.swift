import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    // States for side menus
    @State private var showMainMenu = false
    @State private var showSettingsMenu = false
    
    // Matched geometry namespace for animating icons
    @Namespace private var menuIconNamespace
    
    // Horizontal padding for icons (using the global horizontal padding from UIStyles)
    private let menuIconHorizontalPadding: CGFloat = UIStyles.globalHorizontalPadding
    
    var body: some View {
        ZStack {
            // Enforce full black background to avoid white flashes
            UIStyles.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    // MAIN CONTENT
                    ZStack {
                        VStack(spacing: 0) {
                            // TOP BAR
                            HStack {
                                // Always show left menu icon (now without opacity modifier).
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showSettingsMenu { showSettingsMenu = false }
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(.horizontal, menuIconHorizontalPadding)
                                
                                Spacer()
                                
                                // Always show right settings icon (now without opacity modifier).
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showMainMenu { showMainMenu = false }
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(.horizontal, menuIconHorizontalPadding)
                            }
                            .padding(.top, UIStyles.topSpacing)
                            .padding(.bottom, 10)
                            
                            // TAB BAR (header row)
                            TabBarView(selectedTab: $selectedTab)
                                .padding(.top, 20)
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
                        .background(UIStyles.appBackground.ignoresSafeArea())
                        .cornerRadius((showMainMenu || showSettingsMenu) ? 20 : 0)
                    }
                    // Offset main content and apply blur effect when a menu is open.
                    .offset(x: showMainMenu ? geo.size.width * 0.6 :
                            (showSettingsMenu ? -geo.size.width * 0.6 : 0))
                    .blur(radius: (showMainMenu || showSettingsMenu) ? 5 : 0)
                    .animation(.easeInOut, value: showMainMenu || showSettingsMenu)
                    .edgesIgnoringSafeArea(.all)
                    
                    // BLACK OVERLAY for tap-outside to close menus.
                    if showMainMenu || showSettingsMenu {
                        Color.black
                            .opacity(0.4)
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
                        HStack(spacing: 0) {
                            VStack {
                                HStack {
                                    Spacer()
                                    // Icon inside left menu to close the menu.
                                    AnimatedMenuIcon(isOpen: showMainMenu)
                                        .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                showMainMenu = false
                                            }
                                        }
                                        .padding(.horizontal, menuIconHorizontalPadding)
                                }
                                .padding(.vertical, UIStyles.topSpacing)
                                Spacer()
                            }
                            .frame(minWidth: geo.size.width * 0.8, maxWidth: geo.size.width * 0.8, minHeight: 0, maxHeight: .infinity, alignment: .top)
                            .background(UIStyles.secondaryBackground.ignoresSafeArea())
                            .transition(.move(edge: .leading))
                            
                            Spacer()
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                    
                    // RIGHT SIDE MENU
                    if showSettingsMenu {
                        HStack(spacing: 0) {
                            Spacer()
                            VStack {
                                HStack {
                                    // Icon inside right menu to close the settings menu.
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
                                .padding(.vertical, UIStyles.topSpacing)
                                Spacer()
                            }
                            .frame(minWidth: geo.size.width * 0.8, maxWidth: geo.size.width * 0.8, minHeight: 0, maxHeight: .infinity, alignment: .top)
                            .background(UIStyles.secondaryBackground.ignoresSafeArea())
                            .transition(.move(edge: .trailing))
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
        }
    }
}

struct AnimatedMenuIcon: View {
    var isOpen: Bool
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lineHeight: CGFloat = 2
            let spacing: CGFloat = 8
            
            ZStack(alignment: .topLeading) {
                // Top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w * 0.8 : w, height: lineHeight)
                // Bottom line
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
                // Top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                
                // Top circle
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: circleDiameter, height: circleDiameter)
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: circleDiameter, height: circleDiameter)
                }
                .offset(x: isOpen ? 2 : (width - circleDiameter - 2), y: -circleDiameter/2)
                
                // Bottom line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                    .offset(y: spacing)
                
                // Bottom circle
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