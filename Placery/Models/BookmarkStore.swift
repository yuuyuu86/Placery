import CoreLocation
import Observation

@MainActor
@Observable
final class BookmarkStore {
    static let freeMonthlyLimit = 5

    var bookmarks: [Bookmark] = [] {
        didSet { persist() }
    }
    var justOpened: Bookmark?

    /// サインインしているユーザーのハンドル。自分の投稿の判定に使う。
    var currentUser = AuthStore.localHandle

    private static let fileURL = URL.applicationSupportDirectory.appending(path: "bookmarks.json")

    init() {
        bookmarks = Self.loadFromDisk() ?? Bookmark.samples
    }

    /// 無料プランの上限判定に使う、今月自分が挟んだ枚数。
    var bookmarksThisMonth: Int {
        let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .distantPast
        return mine.filter { $0.postedAt >= monthStart }.count
    }

    func removeAllLocalData() {
        bookmarks = []
        justOpened = nil
        PhotoLibrary.shared.deleteAll()
    }

    private static func loadFromDisk() -> [Bookmark]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([Bookmark].self, from: data)
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(bookmarks) else { return }
        try? FileManager.default.createDirectory(
            at: URL.applicationSupportDirectory,
            withIntermediateDirectories: true
        )
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    var mine: [Bookmark] {
        bookmarks.filter { $0.author == currentUser }
    }

    /// サインイン前に挟んだしおりを、サインイン後のハンドルに引き継ぐ。
    func reassignAuthor(from previous: String, to handle: String) {
        guard previous != handle else { return }
        for index in bookmarks.indices where bookmarks[index].author == previous {
            bookmarks[index].author = handle
        }
    }

    /// 公開範囲とブロック状態を適用した、その人に見えるしおりだけを返す。
    func visible(using social: SocialStore) -> [Bookmark] {
        bookmarks.filter { bookmark in
            if social.isBlocked(bookmark.author) { return false }
            if bookmark.author == currentUser { return true }

            switch bookmark.visibility {
            case .privateOnly: return false
            case .followers: return social.isFollowing(bookmark.author)
            case .everyone: return true
            }
        }
    }

    func opened(using social: SocialStore) -> [Bookmark] {
        visible(using: social).filter(\.isOpened)
    }

    func authors(using social: SocialStore) -> [String] {
        let names = bookmarks
            .map(\.author)
            .filter { $0 != currentUser && !social.isBlocked($0) }
        return Array(Set(names)).sorted()
    }

    func evaluateProximity(from location: CLLocation) {
        for index in bookmarks.indices where !bookmarks[index].isOpened {
            let distance = location.distance(from: bookmarks[index].location)
            if distance <= bookmarks[index].unlockRadius {
                open(at: index)
            }
        }
    }

    func open(_ bookmark: Bookmark) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
        open(at: index)
    }

    func open(id: UUID) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }), !bookmarks[index].isOpened else { return }
        open(at: index)
    }

    func add(_ bookmark: Bookmark) {
        bookmarks.insert(bookmark, at: 0)
    }

    /// iCloudから取得したしおりのうち、手元にないものだけを取り込む。
    func merge(_ fetched: [Bookmark]) {
        let existing = Set(bookmarks.map(\.id))
        let additions = fetched.filter { !existing.contains($0.id) }
        guard !additions.isEmpty else { return }
        bookmarks.append(contentsOf: additions)
    }

    func distance(to bookmark: Bookmark, from location: CLLocation?) -> CLLocationDistance? {
        location?.distance(from: bookmark.location)
    }

    private func open(at index: Int) {
        bookmarks[index].openedAt = .now
        justOpened = bookmarks[index]
    }
}
