import SwiftUI

struct AlbumScreen: View {
    @Environment(BookmarkStore.self) private var store
    @Environment(SocialStore.self) private var social

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let opened = store.opened(using: social)

        return NavigationStack {
            Group {
                if opened.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(opened) { bookmark in
                                NavigationLink {
                                    BookmarkDetailScreen(bookmark: bookmark)
                                } label: {
                                    card(bookmark)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.pageBackground)
            .navigationTitle("アルバム")
        }
    }

    private func card(_ bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BookmarkPhoto(bookmark: bookmark)
                .frame(height: 124)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.placeName)
                    .font(.mincho(15, bold: true))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Text(bookmark.openedAt?.formatted(.dateTime.year().month().day()) ?? "現地不要のしおり")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 34))
                .foregroundStyle(Color.lock)
            Text("まだ開いたしおりがありません")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.ink)
            Text("地図のピンに近づくと、その場所のしおりが開きます。")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    AlbumScreen()
        .environment(BookmarkStore())
}
