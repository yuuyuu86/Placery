import CoreLocation
import Observation

@MainActor
@Observable
final class LocationStore {
    private(set) var location: CLLocation?
    private(set) var authorization: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var updates: Task<Void, Never>?

    init() {
        authorization = manager.authorizationStatus
    }

    var canRequestAlways: Bool {
        authorization == .authorizedWhenInUse
    }

    func requestWhenInUse() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func start() {
        guard updates == nil else { return }
        requestWhenInUse()

        updates = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let self else { return }
                    authorization = manager.authorizationStatus
                    if let location = update.location {
                        self.location = location
                    }
                }
            } catch {
                // 権限拒否や位置情報オフのときは更新が止まるだけで、アプリは地図とアルバムを閲覧できる状態を保つ。
            }
        }
    }
}
