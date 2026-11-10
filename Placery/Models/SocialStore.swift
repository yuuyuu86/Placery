import Foundation
import Observation

struct Report: Identifiable, Codable, Hashable {
    enum Reason: String, CaseIterable, Codable, Identifiable {
        case inappropriate = "不適切な内容"
        case wrongLocation = "位置情報が正しくない"
        case spam = "スパム・宣伝"
        case privacyConcern = "プライバシーの侵害"
        case other = "その他"

        var id: String { rawValue }
    }

    var id = UUID()
    var bookmarkID: UUID
    var author: String
    var reason: Reason
    var detail: String
    var reportedAt: Date
    var isSynced = false
}

@MainActor
@Observable
final class SocialStore {
    private(set) var following: Set<String>
    private(set) var blocked: Set<String>
    private(set) var reports: [Report]

    /// サインインしているユーザーのハンドル。サインアウト中は端末ローカルの既定値。
    var currentUser = AuthStore.localHandle

    /// フォローやブロックが変わったときに、その内容をiCloudへ送るために呼ばれる。
    var onMutate: (@MainActor (SocialStore) -> Void)?

    private let defaults = UserDefaults.standard

    init() {
        following = Set(defaults.stringArray(forKey: Keys.following) ?? ["yui_travel", "sora__"])
        blocked = Set(defaults.stringArray(forKey: Keys.blocked) ?? [])
        reports = (try? JSONDecoder().decode([Report].self, from: defaults.data(forKey: Keys.reports) ?? Data())) ?? []
    }

    func isFollowing(_ author: String) -> Bool {
        following.contains(author)
    }

    func toggleFollow(_ author: String) {
        guard author != currentUser else { return }
        if following.contains(author) {
            following.remove(author)
        } else {
            following.insert(author)
        }
        defaults.set(Array(following), forKey: Keys.following)
        onMutate?(self)
    }

    func isBlocked(_ author: String) -> Bool {
        blocked.contains(author)
    }

    func block(_ author: String) {
        guard author != currentUser else { return }
        blocked.insert(author)
        following.remove(author)
        defaults.set(Array(blocked), forKey: Keys.blocked)
        defaults.set(Array(following), forKey: Keys.following)
        onMutate?(self)
    }

    func unblock(_ author: String) {
        blocked.remove(author)
        defaults.set(Array(blocked), forKey: Keys.blocked)
        onMutate?(self)
    }

    /// iCloudに保存されていたフォロー・ブロックを取り込む。
    func applyRemote(following remoteFollowing: [String], blocked remoteBlocked: [String]) {
        following = Set(remoteFollowing)
        blocked = Set(remoteBlocked)
        defaults.set(remoteFollowing, forKey: Keys.following)
        defaults.set(remoteBlocked, forKey: Keys.blocked)
    }

    var pendingReports: [Report] {
        reports.filter { !$0.isSynced }
    }

    func markReportSynced(_ id: UUID) {
        guard let index = reports.firstIndex(where: { $0.id == id }) else { return }
        reports[index].isSynced = true
        persistReports()
    }

    func removeAllLocalData() {
        following = []
        blocked = []
        reports = []
        defaults.removeObject(forKey: Keys.following)
        defaults.removeObject(forKey: Keys.blocked)
        defaults.removeObject(forKey: Keys.reports)
    }

    func hasReported(_ bookmark: Bookmark) -> Bool {
        reports.contains { $0.bookmarkID == bookmark.id }
    }

    @discardableResult
    func report(_ bookmark: Bookmark, reason: Report.Reason, detail: String) -> Report {
        let report =
            Report(
                bookmarkID: bookmark.id,
                author: bookmark.author,
                reason: reason,
                detail: detail,
                reportedAt: .now
            )

        reports.append(report)
        persistReports()
        return report
    }

    private func persistReports() {
        if let data = try? JSONEncoder().encode(reports) {
            defaults.set(data, forKey: Keys.reports)
        }
    }

    private enum Keys {
        static let following = "social.following"
        static let blocked = "social.blocked"
        static let reports = "social.reports"
    }
}
