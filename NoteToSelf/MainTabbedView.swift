import SwiftUI

struct MainTabbedView: View {
    @State private var selectedTab: AppTab = .journal
    @State private var showSettingsMenu = false
    
    var body: some View {
        ZStack {
            UIStyles.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut) {
                                showSettingsMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(UIStyles.offWhite)
                        }
                        .padding(.trailing, UIStyles.globalHorizontalPadding)
                    }
                    .padding(.top, UIStyles.topSpacing)
                    .padding(.bottom, 10)
                    
                    // Tab Bar
                    TabBarView(selectedTab: $selectedTab)
                        .padding(.bottom, 20)
                        .frame(height: 50)
                    
                    // Selected Content
                    ZStack {
                        switch selectedTab {
                        case .journal:
                            JournalView()
                        case .insights:
                            InsightsView()
                        case .reflections:
                            ReflectionsView()
                        }
                    }
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            if showSettingsMenu {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showSettingsMenu = false
                        }
                    }
                
                GeometryReader { geo in
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation {
                                    showSettingsMenu = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                        Text("Settings Menu Here")
                            .font(UIStyles.headingFont)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: geo.size.width * 0.8, maxHeight: .infinity)
                    .background(Color(hex: "#111111"))
                    .transition(.move(edge: .trailing))
                }
            }
        }
    }
}

struct MainTabbedView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabbedView()
    }
}