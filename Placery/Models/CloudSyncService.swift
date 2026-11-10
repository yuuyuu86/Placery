import CloudKit
import CoreLocation
import Observation

@MainActor
@Observable
final class CloudSyncService {
    enum Status: Equatable {
        case idle
        case unavailable(String)
        case syncing
        case synced(Date)
        case failed(String)

        var label: String {
            switch self {
            case .idle: "未同期"
            case .unavailable(let reason): reason
            case .syncing: "同期中…"
            case .synced(let date): "\(date.formatted(date: .omitted, time: .shortened)) に同期"
            case .failed: "同期に失敗しました"
            }
        }
    }

    private(set) var status: Status = .idle

    private let container = CKContainer(identifier: "iCloud.com.yutamizutani.placery")

    private var publicDatabase: CKDatabase { container.publicCloudDatabase }
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }

    func accountIsAvailable() async -> Bool {
        do {
            let account = try await container.accountStatus()
            switch account {
            case .available:
                return true
            case .noAccount:
                status = .unavailable("iPhoneでiCloudにサインインすると同期できます")
            case .restricted:
                status = .unavailable("この端末ではiCloudが制限されています")
            default:
                status = .unavailable("iCloudを利用できません")
            }
        } catch {
            status = .unavailable("iCloudの状態を確認できませんでした")
        }
        return false
    }

    func push(_ bookmark: Bookmark) async {
        guard await accountIsAvailable() else { return }

        status = .syncing
        do {
            let database = bookmark.visibility == .privateOnly ? privateDatabase : publicDatabase
            _ = try await database.save(makeRecord(from: bookmark))
            status = .synced(.now)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    /// 現在地のまわりに挟まれた、全体公開のしおりを取ってくる。
    func fetchNearby(_ coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 5000) async -> [Bookmark] {
        guard await accountIsAvailable() else { return [] }

        status = .syncing
        let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let predicate = NSPredicate(
            format: "distanceToLocation:fromLocation:(location, %@) < %f",
            center,
            radius
        )

        do {
            let query = CKQuery(recordType: Self.recordType, predicate: predicate)
            let (matches, _) = try await publicDatabase.records(matching: query)
            let bookmarks = matches.compactMap { try? $0.1.get() }.compactMap(makeBookmark(from:))
            status = .synced(.now)
            return bookmarks
        } catch {
            status = .failed(error.localizedDescription)
            return []
        }
    }

    // MARK: - 通報

    /// 通報を運営が確認できる場所(Public DB)へ送る。送れたかどうかを返す。
    func submitReport(_ report: Report, reporterID: String?) async -> Bool {
        guard await accountIsAvailable() else { return false }

        let record = CKRecord(
            recordType: Self.reportRecordType,
            recordID: CKRecord.ID(recordName: report.id.uuidString)
        )
        record["bookmarkID"] = report.bookmarkID.uuidString as CKRecordValue
        record["reportedAuthor"] = report.author as CKRecordValue
        record["reason"] = report.reason.rawValue as CKRecordValue
        record["detail"] = report.detail as CKRecordValue
        record["reportedAt"] = report.reportedAt as CKRecordValue
        if let reporterID {
            record["reporter"] = reporterID as CKRecordValue
        }

        do {
            _ = try await publicDatabase.save(record)
            return true
        } catch {
            status = .failed(error.localizedDescription)
            return false
        }
    }

    // MARK: - フォロー・ブロックの同期

    func saveSocialState(following: [String], blocked: [String]) async {
        guard await accountIsAvailable() else { return }

        let record = CKRecord(
            recordType: Self.socialRecordType,
            recordID: CKRecord.ID(recordName: "socialState")
        )
        record["following"] = following as CKRecordValue
        record["blocked"] = blocked as CKRecordValue

        do {
            _ = try await privateDatabase.save(record)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func loadSocialState() async -> (following: [String], blocked: [String])? {
        guard await accountIsAvailable() else { return nil }

        let id = CKRecord.ID(recordName: "socialState")
        guard let record = try? await privateDatabase.record(for: id) else { return nil }

        return (
            following: record["following"] as? [String] ?? [],
            blocked: record["blocked"] as? [String] ?? []
        )
    }

    // MARK: - アカウント削除

    /// 自分が挟んだしおりとフォロー情報をiCloudから消す。
    func deleteMyData(bookmarks: [Bookmark]) async {
        guard await accountIsAvailable() else { return }

        status = .syncing
        for bookmark in bookmarks {
            let database = bookmark.visibility == .privateOnly ? privateDatabase : publicDatabase
            _ = try? await database.deleteRecord(withID: CKRecord.ID(recordName: bookmark.id.uuidString))
        }

        _ = try? await privateDatabase.deleteRecord(withID: CKRecord.ID(recordName: "socialState"))
        status = .idle
    }

    // MARK: - レコード変換

    private static let recordType = "Bookmark"
    private static let reportRecordType = "Report"
    private static let socialRecordType = "SocialState"

    private func makeRecord(from bookmark: Bookmark) -> CKRecord {
        let record = CKRecord(
            recordType: Self.recordType,
            recordID: CKRecord.ID(recordName: bookmark.id.uuidString)
        )

        record["placeName"] = bookmark.placeName as CKRecordValue
        record["note"] = bookmark.note as CKRecordValue
        record["rating"] = bookmark.rating as CKRecordValue
        record["tags"] = bookmark.tags as CKRecordValue
        record["author"] = bookmark.author as CKRecordValue
        record["postedAt"] = bookmark.postedAt as CKRecordValue
        record["location"] = bookmark.location as CKRecordValue
        record["visibility"] = bookmark.visibility.rawValue as CKRecordValue
        record["requiresVisit"] = bookmark.requiresVisit as CKRecordValue
        record["unlockRadius"] = bookmark.unlockRadius as CKRecordValue
        record["photoSwatch"] = bookmark.photo.rawValue as CKRecordValue

        if let name = bookmark.photoFiles.first, let url = PhotoLibrary.shared.url(for: name) {
            record["photo"] = CKAsset(fileURL: url)
        }

        return record
    }

    private func makeBookmark(from record: CKRecord) -> Bookmark? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let placeName = record["placeName"] as? String,
              let note = record["note"] as? String,
              let author = record["author"] as? String,
              let location = record["location"] as? CLLocation,
              let visibility = (record["visibility"] as? String).flatMap(Visibility.init(rawValue:))
        else { return nil }

        var photoFiles: [String] = []
        if let asset = record["photo"] as? CKAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url),
           let name = PhotoLibrary.shared.save(data) {
            photoFiles = [name]
        }

        return Bookmark(
            id: id,
            placeName: placeName,
            note: note,
            rating: record["rating"] as? Int ?? 0,
            tags: record["tags"] as? [String] ?? [],
            author: author,
            postedAt: record["postedAt"] as? Date ?? .now,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            visibility: visibility,
            requiresVisit: record["requiresVisit"] as? Bool ?? true,
            unlockRadius: record["unlockRadius"] as? Double ?? 50,
            photo: (record["photoSwatch"] as? String).flatMap(PhotoSwatch.init(rawValue:)) ?? .pond,
            photoFiles: photoFiles
        )
    }
}
