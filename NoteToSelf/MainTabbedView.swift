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
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        // Subscription UI
                        Text("Settings")
                            .font(UIStyles.headingFont)
                            .foregroundColor(.white)
                        
                        SubscriptionSettingsView()
                        
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

struct SubscriptionSettingsView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscriptionManager.isUserSubscribed {
                Text("You are subscribed!")
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.green)
                
                Button("Unsubscribe (Debug)") {
                    subscriptionManager.unsubscribeDebug()
                }
                .font(UIStyles.bodyFont)
                .foregroundColor(.red)
            } else {
                Text("Subscribe for unlimited reflections & advanced analytics.")
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                
                Button("Subscribe Monthly") {
                    subscriptionManager.subscribeMonthly()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(8)
                
                Button("Restore Purchases") {
                    subscriptionManager.restorePurchase()
                }
                .font(UIStyles.bodyFont)
                .foregroundColor(.white)
            }
        }
        .padding()
    }
}

struct MainTabbedView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabbedView()
    }
}