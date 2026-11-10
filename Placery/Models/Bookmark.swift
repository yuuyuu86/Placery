import CoreLocation
import SwiftUI

enum Visibility: String, CaseIterable, Identifiable, Hashable, Codable {
    case privateOnly = "非公開"
    case followers = "フォロワー"
    case everyone = "全体公開"

    var id: String { rawValue }
}

enum PhotoSwatch: String, CaseIterable, Identifiable, Hashable, Codable {
    case pond, sand, dusk

    var id: String { rawValue }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var colors: [Color] {
        switch self {
        case .pond:
            [Color(red: 0.61, green: 0.72, blue: 0.58), Color(red: 0.25, green: 0.35, blue: 0.25)]
        case .sand:
            [Color(red: 0.79, green: 0.73, blue: 0.61), Color(red: 0.48, green: 0.42, blue: 0.31)]
        case .dusk:
            [Color(red: 0.55, green: 0.55, blue: 0.62), Color(red: 0.20, green: 0.22, blue: 0.30)]
        }
    }
}

struct Bookmark: Identifiable, Hashable, Codable {
    var id = UUID()
    var placeName: String
    var note: String
    var rating: Int
    var tags: [String]
    var author: String
    var postedAt: Date
    var latitude: Double
    var longitude: Double
    var visibility: Visibility
    var requiresVisit: Bool
    var unlockRadius: CLLocationDistance = 50
    var openedAt: Date?
    var likes: Int = 0
    /// 実際の写真がない見本データ用の色味。写真があるしおりでは使わない。
    var photo: PhotoSwatch
    var photoFiles: [String] = []

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var isOpened: Bool {
        !requiresVisit || openedAt != nil
    }
}

extension Bookmark {
    static let samples: [Bookmark] = [
        Bookmark(
            placeName: "井の頭公園 わき道",
            note: "ベンチから見える池がすごく静かで、時間が止まったみたいだった。休日なのに人がほとんど来ない場所で、ここだけ空気が違う感じがする。",
            rating: 4,
            tags: ["絶景", "穴場"],
            author: "yui_travel",
            postedAt: .now.addingTimeInterval(-60 * 60 * 24 * 120),
            latitude: 35.70060,
            longitude: 139.58030,
            visibility: .everyone,
            requiresVisit: true,
            likes: 24,
            photo: .pond
        ),
        Bookmark(
            placeName: "橋の下のベンチ",
            note: "水面に反射した光が天井に揺れていて、ずっと見ていられる。夕方がいちばんきれい。",
            rating: 5,
            tags: ["絶景"],
            author: "kenji.p",
            postedAt: .now.addingTimeInterval(-60 * 60 * 24 * 40),
            latitude: 35.70120,
            longitude: 139.57920,
            visibility: .everyone,
            requiresVisit: true,
            likes: 8,
            photo: .dusk
        ),
        Bookmark(
            placeName: "階段の上の桜",
            note: "見上げたときの枝の広がりが忘れられない。来年もここに来る。",
            rating: 4,
            tags: ["絶景", "春"],
            author: "sora__",
            postedAt: .now.addingTimeInterval(-60 * 60 * 24 * 300),
            latitude: 35.69950,
            longitude: 139.58200,
            visibility: .followers,
            requiresVisit: true,
            likes: 15,
            photo: .sand
        ),
        Bookmark(
            placeName: "代々木公園 けやき並木",
            note: "はじめて友達とピクニックした場所。あの日の光がそのまま残っている気がする。",
            rating: 5,
            tags: ["思い出"],
            author: "you",
            postedAt: .now.addingTimeInterval(-60 * 60 * 24 * 500),
            latitude: 35.67200,
            longitude: 139.69490,
            visibility: .everyone,
            requiresVisit: true,
            openedAt: .now.addingTimeInterval(-60 * 60 * 24 * 10),
            likes: 32,
            photo: .pond
        ),
        Bookmark(
            placeName: "路地裏の喫茶店",
            note: "窓際の席から見える通りがちょうどいい速度で流れていく。コーヒーが濃い。",
            rating: 4,
            tags: ["カフェ", "穴場"],
            author: "you",
            postedAt: .now.addingTimeInterval(-60 * 60 * 24 * 60),
            latitude: 35.70240,
            longitude: 139.58390,
            visibility: .privateOnly,
            requiresVisit: false,
            likes: 0,
            photo: .sand
        ),
    ]
}
