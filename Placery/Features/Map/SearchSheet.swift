import SwiftUI

struct SearchSheet: View {
    var bookmarks: [Bookmark]
    var onSelect: (Bookmark) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [Bookmark] {
        guard !query.isEmpty else { return bookmarks }
        return bookmarks.filter { bookmark in
            bookmark.placeName.localizedStandardContains(query)
                || bookmark.tags.contains { $0.localizedStandardContains(query) }
                || bookmark.author.localizedStandardContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ContentUnavailableView(
                        "見つかりませんでした",
                        systemImage: "magnifyingglass",
                        description: Text("場所の名前・タグ・ユーザー名で探せます。")
                    )
                } else {
                    List(results) { bookmark in
                        Button {
                            onSelect(bookmark)
                            dismiss()
                        } label: {
                            row(bookmark)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surface)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.pageBackground)
            .navigationTitle("探す")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "場所・タグ・ユーザー名")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func row(_ bookmark: Bookmark) -> some View {
        HStack(spacing: 12) {
            Group {
                if bookmark.isOpened {
                    BookmarkPhoto(bookmark: bookmark)
                } else {
                    Rectangle().fill(Color.lockTint)
                }
            }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if !bookmark.isOpened {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.lock)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(bookmark.placeName)
                    .font(.mincho(15, bold: true))
                    .foregroundStyle(Color.ink)
                Text(bookmark.isOpened ? "@\(bookmark.author)" : "@\(bookmark.author) · 現地で解錠")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.lock)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchSheet(bookmarks: Bookmark.samples) { _ in }
}
