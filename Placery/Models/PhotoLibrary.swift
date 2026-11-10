import UIKit

/// しおりに添えた写真をアプリ内のファイルとして保管する。
@MainActor
final class PhotoLibrary {
    static let shared = PhotoLibrary()

    private let cache = NSCache<NSString, UIImage>()
    private let directory: URL

    private init() {
        let base = URL.applicationSupportDirectory.appending(path: "Photos", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        directory = base
    }

    func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.9) else { return nil }

        let name = "\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: directory.appending(path: name), options: .atomic)
            cache.setObject(image, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    func url(for name: String) -> URL? {
        let url = directory.appending(path: name)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    func image(named name: String) -> UIImage? {
        if let cached = cache.object(forKey: name as NSString) { return cached }

        guard let data = try? Data(contentsOf: directory.appending(path: name)),
              let image = UIImage(data: data) else { return nil }

        cache.setObject(image, forKey: name as NSString)
        return image
    }

    func delete(_ names: [String]) {
        for name in names {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
            cache.removeObject(forKey: name as NSString)
        }
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        cache.removeAllObjects()
    }
}
