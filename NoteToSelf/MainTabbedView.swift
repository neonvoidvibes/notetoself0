import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    // States for side menus
    @State private var showMainMenu = false
    @State private var showSettingsMenu = false
    
    // Matched geometry namespace for animating icons
    @Namespace private var menuIconNamespace
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MAIN CONTENT
                ZStack {
                    VStack(spacing: 0) {
                        
                        // TOP BAR
                        HStack {
                            // Left menu icon (animated)
                            if !showMainMenu {
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showSettingsMenu {
                                                showSettingsMenu = false
                                            }
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(20) // increase tap area
                            }
                            
                            Spacer()
                            
                            // Right settings icon (animated)
                            if !showSettingsMenu {
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if showMainMenu {
                                                showMainMenu = false
                                            }
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(20) // increase tap area
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
                    // removed the blur effect
                }
                .edgesIgnoringSafeArea(.all)
                
                // TAP-OUTSIDE OVERLAY to close menus
                if showMainMenu || showSettingsMenu {
                    // A transparent overlay covering the entire screen except the menu area,
                    // to allow tapping outside to close.
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
                            // Animate the same left menu icon inside
                            if showMainMenu {
                                HStack {
                                    Spacer()
                                    AnimatedMenuIcon(isOpen: showMainMenu)
                                        .matchedGeometryEffect(id: "leftMenuIcon", in: menuIconNamespace)
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                showMainMenu.toggle()
                                            }
                                        }
                                        .padding(16)
                                }
                            }
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.75) // open to 75%
                        .padding(.vertical, 20) // add space above/below
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
                            // Animate the same right settings icon inside
                            if showSettingsMenu {
                                HStack {
                                    AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                        .matchedGeometryEffect(id: "rightSettingsIcon", in: menuIconNamespace)
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                showSettingsMenu.toggle()
                                            }
                                        }
                                        .padding(16)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.75) // open to 75%
                        .padding(.vertical, 20) // add space above/below
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
                
                // Top circle: add fill #000000 behind stroke
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
                
                // Bottom circle: add fill #000000 behind stroke
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