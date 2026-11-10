import SwiftUI

struct BookmarkDetailScreen: View {
    var bookmark: Bookmark

    @Environment(SocialStore.self) private var social
    @Environment(\.dismiss) private var dismiss
    @State private var isReporting = false
    @State private var isConfirmingBlock = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hero

                VStack(alignment: .leading, spacing: 14) {
                    Text(bookmark.placeName)
                        .font(.mincho(23, bold: true))
                        .foregroundStyle(Color.ink)

                    HStack(spacing: 9) {
                        BookmarkPhoto(bookmark: bookmark)
                            .frame(width: 22, height: 22)
                            .clipShape(.circle)
                        Text("@\(bookmark.author)")
                        Text("·")
                        Text(bookmark.postedAt.formatted(.dateTime.year().month().day()))
                        Spacer()
                        stars
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSoft)

                    Text(bookmark.note)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .foregroundStyle(Color.ink)

                    if !bookmark.tags.isEmpty {
                        HStack(spacing: 7) {
                            ForEach(bookmark.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.mossDeep)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.mossTint))
                            }
                        }
                    }

                    Divider()

                    actions

                    if bookmark.requiresVisit {
                        Label("このしおりは一度開いたので、これからはどこにいても読み返せます。", systemImage: "book.closed")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mossDeep)
                            .padding(11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.mossTint))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .background(Color.pageBackground)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if bookmark.author != social.currentUser {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(social.isFollowing(bookmark.author) ? "フォロー解除" : "フォローする", systemImage: "person.badge.plus") {
                            social.toggleFollow(bookmark.author)
                        }
                        Button("通報する", systemImage: "flag") { isReporting = true }
                        Button("@\(bookmark.author) をブロック", systemImage: "hand.raised", role: .destructive) {
                            isConfirmingBlock = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .sheet(isPresented: $isReporting) {
            ReportSheet(bookmark: bookmark)
        }
        .confirmationDialog(
            "@\(bookmark.author) をブロックしますか?",
            isPresented: $isConfirmingBlock,
            titleVisibility: .visible
        ) {
            Button("ブロックする", role: .destructive) {
                social.block(bookmark.author)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このアカウントのしおりは、地図にもアルバムにも表示されなくなります。")
        }
    }

    private var hero: some View {
        BookmarkPhoto(bookmark: bookmark)
            .frame(height: 290)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                if let openedAt = bookmark.openedAt {
                    Text("\(openedAt.formatted(.dateTime.year().month().day())) にあなたが開きました")
                        .font(.system(size: 11))
                        .foregroundStyle(MomentPalette.ink)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .padding(16)
                }
            }
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= bookmark.rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.moss)
            }
        }
    }

    private var actions: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                } label: {
                    Label("\(bookmark.likes)", systemImage: "heart")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)

                Button {
                } label: {
                    Label("保存", systemImage: "bookmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
            .foregroundStyle(Color.ink)
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkDetailScreen(bookmark: Bookmark.samples[3])
    }
}
