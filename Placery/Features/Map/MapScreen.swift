import MapKit
import SwiftUI

struct MapScreen: View {
    @Environment(BookmarkStore.self) private var store
    @Environment(LocationStore.self) private var location
    @Environment(SocialStore.self) private var social
    @Environment(ProximityMonitor.self) private var monitor

    @AppStorage("hasProximityAlerts") private var hasProximityAlerts = false
    @AppStorage("dismissedAlertCard") private var dismissedAlertCard = false

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: .inokashira,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    )
    @State private var lockedPreview: Bookmark?
    @State private var detail: Bookmark?
    @State private var isComposing = false
    @State private var isSearching = false

    private var bookmarks: [Bookmark] {
        store.visible(using: social)
    }

    /// 現在地の表示自体がシステムの許可ダイアログを出すため、許可が下りるまでは地図に出さない。
    private var showsUserLocation: Bool {
        location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
    }

    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                if showsUserLocation {
                    UserAnnotation()
                }

                ForEach(bookmarks) { bookmark in
                    Annotation(bookmark.isOpened ? bookmark.placeName : "", coordinate: bookmark.coordinate) {
                        pin(for: bookmark)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                if showsUserLocation {
                    MapUserLocationButton()
                }
            }
            .safeAreaInset(edge: .top) { topBar }
            .overlay(alignment: .bottom) { bottomControls }
            .navigationDestination(item: $detail) { BookmarkDetailScreen(bookmark: $0) }
            .sheet(item: $lockedPreview) { bookmark in
                LockedPreviewSheet(bookmark: bookmark, distance: store.distance(to: bookmark, from: location.location))
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isComposing) {
                ComposeScreen(coordinate: location.location?.coordinate)
            }
            .sheet(isPresented: $isSearching) {
                SearchSheet(bookmarks: bookmarks) { bookmark in
                    focus(on: bookmark)
                }
            }
        }
    }

    @ViewBuilder
    private func pin(for bookmark: Bookmark) -> some View {
        VStack(spacing: 5) {
            if bookmark.isOpened {
                OpenBookMark(bookmark: bookmark)
            } else {
                ClosedBookMark(highlighted: isNear(bookmark))
            }

            if bookmark.isOpened {
                Text(bookmark.placeName)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.mossDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.surface))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            }
        }
        .onTapGesture {
            if bookmark.isOpened {
                detail = bookmark
            } else {
                lockedPreview = bookmark
            }
        }
    }

    private var topBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    isSearching = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                        Text("場所やしおりを探す")
                            .font(.system(size: 14))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Color.inkSoft)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)

                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(alignment: .topTrailing) {
                        if !hasProximityAlerts {
                            Circle()
                                .fill(Color.moss)
                                .frame(width: 8, height: 8)
                                .offset(x: -9, y: 9)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    private var bottomControls: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if shouldOfferAlerts {
                alertOptInCard
            }

            Button {
                isComposing = true
            } label: {
                Label("しおりを挟む", systemImage: "bookmark.fill")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.mossDeep)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    /// 位置情報を「使用中のみ」許可した人にだけ、あとから「常に許可」＋通知をお願いする。
    private var shouldOfferAlerts: Bool {
        location.canRequestAlways && !hasProximityAlerts && !dismissedAlertCard
    }

    private var alertOptInCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 16))
                .foregroundStyle(Color.mossDeep)

            VStack(alignment: .leading, spacing: 4) {
                Text("近くのしおりを知らせる")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text("アプリを開いていなくても、しおりのある場所に近づいたら通知します。")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    Button("通知を受け取る") {
                        Task {
                            hasProximityAlerts = await monitor.requestNotificationPermission()
                            location.requestAlways()
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mossDeep)

                    Button("あとで") { dismissedAlertCard = true }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSoft)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.surface))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
    }

    private func focus(on bookmark: Bookmark) {
        withAnimation {
            camera = .region(
                MKCoordinateRegion(
                    center: bookmark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                )
            )
        }
    }

    private func isNear(_ bookmark: Bookmark) -> Bool {
        guard let distance = store.distance(to: bookmark, from: location.location) else { return false }
        return distance < 300
    }
}

private struct LockedPreviewSheet: View {
    var bookmark: Bookmark
    var distance: CLLocationDistance?

    @Environment(SocialStore.self) private var social
    @State private var isReporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.lockTint)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.lock)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.placeName)
                        .font(.mincho(19, bold: true))
                        .foregroundStyle(Color.ink)
                    Text("@\(bookmark.author) さんのしおり")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkSoft)
                }
                Spacer(minLength: 0)

                Menu {
                    Button(social.isFollowing(bookmark.author) ? "フォロー解除" : "フォローする", systemImage: "person.badge.plus") {
                        social.toggleFollow(bookmark.author)
                    }
                    Button("通報する", systemImage: "flag") { isReporting = true }
                    Button("@\(bookmark.author) をブロック", systemImage: "hand.raised", role: .destructive) {
                        social.block(bookmark.author)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkSoft)
                        .frame(width: 32, height: 32)
                }
            }

            if let distance {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(distance.formattedDistance)
                            .font(.system(size: 26, weight: .bold))
                            .monospacedDigit()
                        Text("先")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkSoft)
                    }
                    ProgressView(value: min(1, max(0.05, 1 - distance / 1000)))
                        .tint(Color.moss)
                }
            }

            Label("半径\(Int(bookmark.unlockRadius))m以内に入ると、自動でしおりが開きます。", systemImage: "figure.walk")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSoft)

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .sheet(isPresented: $isReporting) {
            ReportSheet(bookmark: bookmark)
        }
    }
}

extension CLLocationDistance {
    var formattedDistance: String {
        self >= 1000 ? String(format: "%.1fkm", self / 1000) : "\(Int(self))m"
    }
}
