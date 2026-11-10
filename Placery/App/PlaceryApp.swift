import SwiftUI

@main
struct PlaceryApp: App {
    @State private var store = BookmarkStore()
    @State private var location = LocationStore()
    @State private var social = SocialStore()
    @State private var monitor = ProximityMonitor()
    @State private var subscription = SubscriptionStore()
    @State private var auth = AuthStore()
    @State private var cloud = CloudSyncService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(location)
                .environment(social)
                .environment(monitor)
                .environment(subscription)
                .environment(auth)
                .environment(cloud)
                .tint(.moss)
                .task {
                    await auth.refreshCredentialState()
                    await subscription.load()
                }
        }
    }
}
