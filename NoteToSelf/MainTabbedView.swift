import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .overview
    
    // States for side menus
    @State private var showMainMenu = false
    @State private var showSettingsMenu = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Left side main menu (background only, no content yet)
                if showMainMenu {
                    HStack(spacing: 0) {
                        VStack {
                            HStack {
                                Spacer()
                                // Animated icon top-right corner inside the menu
                                AnimatedMenuIcon(isOpen: showMainMenu)
                                    .onTapGesture {
                                        withAnimation {
                                            showMainMenu.toggle()
                                        }
                                    }
                                    .padding(.top, 40)
                                    .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.7) // Example width
                        .background(UIStyles.secondaryBackground)
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                }
                
                // Right side settings menu (background only, no content yet)
                if showSettingsMenu {
                    HStack(spacing: 0) {
                        Spacer()
                        
                        VStack {
                            HStack {
                                // Animated icon top-left corner inside the settings
                                AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                    .onTapGesture {
                                        withAnimation {
                                            showSettingsMenu.toggle()
                                        }
                                    }
                                    .padding(.top, 40)
                                    .padding(.leading, 16)
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.7)
                        .background(UIStyles.secondaryBackground)
                        .transition(.move(edge: .trailing))
                    }
                }
                
                // Main content with top bar
                ZStack {
                    VStack(spacing: 0) {
                        
                        // Top bar: left menu icon, right settings icon with increased top padding and extra bottom spacing
                        HStack {
                            // Main menu icon on left
                            AnimatedMenuIcon(isOpen: showMainMenu)
                                .onTapGesture {
                                    withAnimation {
                                        if showSettingsMenu {
                                            showSettingsMenu = false
                                        }
                                        showMainMenu.toggle()
                                    }
                                }
                            
                            Spacer()
                            
                            // Settings icon on right
                            AnimatedSettingsIcon(isOpen: showSettingsMenu)
                                .onTapGesture {
                                    withAnimation {
                                        if showMainMenu {
                                            showMainMenu = false
                                        }
                                        showSettingsMenu.toggle()
                                    }
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 60) // Increased top padding from 40 to 60
                        .padding(.bottom, 20) // Added extra space between top bar and headlines list
                        
                        // Tab bar
                        TabBarView(selectedTab: $selectedTab)
                            .frame(height: 50)
                        
                        // The selected content
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
                    .cornerRadius(showMainMenu || showSettingsMenu ? 20 : 0)
                    .offset(x: showMainMenu ? geo.size.width * 0.6 : (showSettingsMenu ? -geo.size.width * 0.6 : 0))
                    .blur(radius: showMainMenu || showSettingsMenu ? 5 : 0)
                    .animation(.easeInOut, value: showMainMenu || showSettingsMenu)
                }
            }
            .edgesIgnoringSafeArea(.all)
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
            let spacing: CGFloat = 8  // Increased spacing from 6 to 8
            
            ZStack(alignment: .topLeading) {
                // Top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w * 0.8 : w, height: lineHeight)
                    .offset(x: 0, y: 0)
                
                // Bottom line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: isOpen ? w : w * 0.8, height: lineHeight)
                    .offset(x: 0, y: spacing)
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
            let spacing: CGFloat = 8  // Increased spacing for consistency
            let circleDiameter: CGFloat = 8  // Increased from 6 to 8
            
            ZStack(alignment: .topLeading) {
                // Top line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                    .offset(x: 0, y: 0)
                // Top circle: border-only, non-filled; inset by 2 points
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .offset(x: isOpen ? 2 : (width - circleDiameter - 2), y: -circleDiameter/2)
                
                // Bottom line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: lineHeight)
                    .offset(x: 0, y: spacing)
                // Bottom circle: border-only, non-filled; inset by 2 points
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: circleDiameter, height: circleDiameter)
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