import CoreLocation
import SwiftUI

struct RootView: View {
    @Environment(BookmarkStore.self) private var store
    @Environment(LocationStore.self) private var location
    @Environment(ProximityMonitor.self) private var monitor
    @Environment(AuthStore.self) private var auth
    @Environment(CloudSyncService.self) private var cloud
    @Environment(SocialStore.self) private var social

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                // オンボーディング中はマップを生成しない。MapKitの現在地表示が、説明より先に
                // システムの許可ダイアログを出してしまうため。
                OnboardingView {
                    hasSeenOnboarding = true
                    location.start()
                }
            } else if !auth.isSignedIn {
                SignInScreen()
            } else {
                mainTabs
            }
        }
        .onChange(of: auth.handle, initial: true) { _, handle in
            adopt(handle)
        }
        .onChange(of: location.authorization) { _, _ in
            Task { await startMonitoringIfAllowed() }
        }
        .onChange(of: location.location) { _, newValue in
            guard let newValue else { return }
            store.evaluateProximity(from: newValue)
            Task { await monitor.sync(bookmarks: store.bookmarks, around: newValue) }
        }
    }

    private var mainTabs: some View {
        @Bindable var store = store

        return TabView {
            Tab("マップ", systemImage: "map") {
                MapScreen()
            }
            Tab("アルバム", systemImage: "books.vertical") {
                AlbumScreen()
            }
            Tab("フォロー", systemImage: "person.2") {
                FollowScreen()
            }
            Tab("マイページ", systemImage: "person.crop.circle") {
                ProfileScreen()
            }
        }
        .fullScreenCover(item: $store.justOpened) { bookmark in
            UnlockMomentView(bookmark: bookmark)
        }
        .task {
            location.start()
            await startMonitoringIfAllowed()
            await syncFromCloud()
            await flushPendingReports()
        }
    }

    /// サインイン状態が変わったら、投稿者の扱いとiCloud連携をそのハンドルに合わせる。
    private func adopt(_ handle: String) {
        let previous = store.currentUser
        store.reassignAuthor(from: previous, to: handle)
        store.currentUser = handle
        social.currentUser = handle

        social.onMutate = { [cloud] social in
            Task { await cloud.saveSocialState(following: Array(social.following), blocked: Array(social.blocked)) }
        }
    }

    private func startMonitoringIfAllowed() async {
        let granted = location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
        guard granted else { return }

        monitor.onEnter = { [weak store] id in
            store?.open(id: id)
        }
        await monitor.start()
        await monitor.sync(bookmarks: store.bookmarks, around: location.location)
    }

    private func syncFromCloud() async {
        let coordinate = location.location?.coordinate ?? .inokashira
        let fetched = await cloud.fetchNearby(coordinate)
        store.merge(fetched)

        if let remote = await cloud.loadSocialState() {
            social.applyRemote(following: remote.following, blocked: remote.blocked)
        }
    }

    /// 送信できていない通報を、起動のたびに送り直す。
    private func flushPendingReports() async {
        for report in social.pendingReports {
            if await cloud.submitReport(report, reporterID: auth.userID) {
                social.markReportSynced(report.id)
            }
        }
    }
}
