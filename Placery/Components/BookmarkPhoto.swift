import SwiftUI

/// 添えられた写真を表示する。まだ写真がない見本データでは色味のグラデーションにフォールバックする。
struct BookmarkPhoto: View {
    var bookmark: Bookmark

    var body: some View {
        if let name = bookmark.photoFiles.first, let image = PhotoLibrary.shared.image(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(bookmark.photo.gradient)
        }
    }
}
