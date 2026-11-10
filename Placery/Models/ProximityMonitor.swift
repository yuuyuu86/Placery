import CoreLocation
import Observation
import UserNotifications

/// 未解錠のしおりをジオフェンスで見張る。
/// iOSの監視上限が20件のため、現在地から近い順に20件だけ登録し、移動に応じて入れ替える。
@MainActor
@Observable
final class ProximityMonitor {
    static let conditionLimit = 20

    private(set) var isActive = false
    private(set) var watchedIDs: [UUID] = []

    var onEnter: ((UUID) -> Void)?

    private var monitor: CLMonitor?
    private var eventsTask: Task<Void, Never>?

    func start() async {
        guard monitor == nil else { return }
        let monitor = await CLMonitor("PlaceryProximityMonitor")
        self.monitor = monitor
        isActive = true

        eventsTask = Task { [weak self] in
            do {
                for try await event in await monitor.events {
                    guard let self else { return }
                    guard event.state == .satisfied,
                          let id = UUID(uuidString: event.identifier) else { continue }
                    onEnter?(id)
                    await notifyOpened(id: id)
                }
            } catch {
                // 監視が終了した場合はフォアグラウンドの距離判定のみで解錠する。
                self?.isActive = false
            }
        }
    }

    func stop() {
        eventsTask?.cancel()
        eventsTask = nil
        monitor = nil
        watchedIDs = []
        isActive = false
    }

    /// 現在地に近い未解錠のしおりだけを監視対象に保つ。
    func sync(bookmarks: [Bookmark], around location: CLLocation?) async {
        guard let monitor else { return }

        let candidates = bookmarks.filter { !$0.isOpened }
        let sorted: [Bookmark] = if let location {
            candidates.sorted { location.distance(from: $0.location) < location.distance(from: $1.location) }
        } else {
            candidates
        }

        let targets = Array(sorted.prefix(Self.conditionLimit))
        let targetIDs = targets.map(\.id)
        guard targetIDs != watchedIDs else { return }

        for identifier in await monitor.identifiers where !targetIDs.map(\.uuidString).contains(identifier) {
            await monitor.remove(identifier)
        }

        let existing = await monitor.identifiers
        for bookmark in targets where !existing.contains(bookmark.id.uuidString) {
            let condition = CLMonitor.CircularGeographicCondition(
                center: bookmark.coordinate,
                radius: bookmark.unlockRadius
            )
            await monitor.add(condition, identifier: bookmark.id.uuidString, assuming: .unsatisfied)
        }

        watchedIDs = targetIDs
    }

    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    private func notifyOpened(id: UUID) async {
        let content = UNMutableNotificationContent()
        content.title = "しおりが開きました"
        content.body = "この場所に挟まれたしおりが読めるようになりました。"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
