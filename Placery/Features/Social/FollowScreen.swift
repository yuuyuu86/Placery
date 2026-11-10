import SwiftUI

struct FollowScreen: View {
    @Environment(BookmarkStore.self) private var store
    @Environment(SocialStore.self) private var social

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("この辺りでしおりを挟んでいる人").sectionLabel()
                        ForEach(store.authors(using: social), id: \.self) { author in
                            authorRow(author)
                        }
                    }

                    if !social.blocked.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ブロック中").sectionLabel()
                            ForEach(Array(social.blocked).sorted(), id: \.self) { author in
                                blockedRow(author)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.pageBackground)
            .navigationTitle("フォロー")
        }
    }

    private func authorRow(_ author: String) -> some View {
        let count = store.bookmarks.filter { $0.author == author }.count
        let isFollowing = social.isFollowing(author)

        return HStack(spacing: 12) {
            Circle()
                .fill(PhotoSwatch.dusk.gradient)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(author)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text("しおり \(count)件")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }

            Spacer()

            Button(isFollowing ? "フォロー中" : "フォロー") {
                social.toggleFollow(author)
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 2)
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .foregroundStyle(isFollowing ? Color.inkSoft : Color.mossDeep)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
        .contextMenu {
            Button("@\(author) をブロック", systemImage: "hand.raised", role: .destructive) {
                social.block(author)
            }
        }
    }

    private func blockedRow(_ author: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.lockTint)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lock)
                }

            Text("@\(author)")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSoft)

            Spacer()

            Button("解除") { social.unblock(author) }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.moss)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
    }
}

#Preview {
    FollowScreen()
        .environment(BookmarkStore())
        .environment(SocialStore())
}
