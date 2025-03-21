import Foundation
import SwiftUI

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isUserSubscribed: Bool = false
    
    private init() {}
    
    func subscribeMonthly() {
        // Stub: For real usage, implement StoreKit 2 or StoreKit 1 flows
        // For now, let's just set the subscription to true
        isUserSubscribed = true
        print("User subscribed to monthly plan (stub).")
    }
    
    func restorePurchase() {
        // Stub: For real usage, implement restore logic
        // Setting isUserSubscribed = true for demonstration
        isUserSubscribed = true
        print("Restore purchase (stub).")
    }
    
    func unsubscribeDebug() {
        // Helper for debugging
        isUserSubscribed = false
        print("User unsubscribed (debug).")
    }
}