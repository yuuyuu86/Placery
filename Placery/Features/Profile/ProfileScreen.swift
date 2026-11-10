import SwiftUI

struct ProfileScreen: View {
    @Environment(BookmarkStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    stats

                    VStack(alignment: .leading, spacing: 10) {
                        Text("挟んだしおり").sectionLabel()
                        ForEach(store.mine) { bookmark in
                            NavigationLink {
                                BookmarkDetailScreen(bookmark: bookmark)
                            } label: {
                                row(bookmark)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .background(Color.pageBackground)
            .navigationTitle("マイページ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(PhotoSwatch.sand.gradient)
                .frame(width: 76, height: 76)
            Text("@you")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.ink)
        }
        .padding(.top, 8)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statTile(title: "挟んだ", value: store.mine.count)
            statTile(title: "開いた", value: store.bookmarks.filter { $0.openedAt != nil }.count)
            statTile(title: "未解錠", value: store.bookmarks.filter { !$0.isOpened }.count)
        }
    }

    private func statTile(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
    }

    private func row(_ bookmark: Bookmark) -> some View {
        HStack(spacing: 12) {
            BookmarkPhoto(bookmark: bookmark)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(bookmark.placeName)
                    .font(.mincho(15, bold: true))
                    .foregroundStyle(Color.ink)
                Text(bookmark.visibility.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Image(systemName: bookmark.requiresVisit ? "lock.fill" : "lock.open")
                .font(.system(size: 12))
                .foregroundStyle(Color.lock)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
    }
}

#Preview {
    ProfileScreen()
        .environment(BookmarkStore())
}
