import SwiftUI
import UIKit

struct SettingsScreen: View {
    @Environment(BookmarkStore.self) private var store
    @Environment(SocialStore.self) private var social
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(AuthStore.self) private var auth
    @Environment(CloudSyncService.self) private var cloud
    @Environment(LocationStore.self) private var location

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasProximityAlerts") private var hasProximityAlerts = false

    @State private var showsPaywall = false
    @State private var exportURL: URL?
    @State private var exportFailed = false
    @State private var isConfirmingDeletion = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                planSection
                syncSection
                notificationSection
                dataSection
                accountSection
            }
            .padding(20)
        }
        .background(Color.pageBackground)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPaywall) { PaywallView() }
        .alert("書き出せませんでした", isPresented: $exportFailed) {
            Button("OK") {}
        } message: {
            Text("しばらくしてからもう一度お試しください。")
        }
        .confirmationDialog(
            "アカウントを削除しますか?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("挟んだしおり、開いたしおり、フォロー中のアカウントがすべて消えます。この操作は取り消せません。")
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プラン").sectionLabel()

            Button {
                showsPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: subscription.isPlus ? "checkmark.seal.fill" : "books.vertical")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.moss)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.isPlus ? "Placery Plus" : "無料プラン")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ink)
                        Text(subscription.isPlus
                             ? "しおりを無制限に挟めます"
                             : "今月あと\(max(0, BookmarkStore.freeMonthlyLimit - store.bookmarksThisMonth))枚挟めます")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.inkSoft)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.lock)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
            }
            .buttonStyle(.plain)
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iCloud同期").sectionLabel()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "icloud")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.moss)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(auth.displayName.map { "\($0) としてサインイン中" } ?? "サインイン中")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ink)
                        Text(cloud.status.label)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.inkSoft)
                    }

                    Spacer()

                    if cloud.status == .syncing {
                        ProgressView()
                    } else {
                        Button("今すぐ同期") {
                            Task {
                                let coordinate = location.location?.coordinate ?? .inokashira
                                store.merge(await cloud.fetchNearby(coordinate))
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.moss)
                    }
                }
                .padding(14)

                Divider().padding(.leading, 52)

                Button {
                    auth.signOut()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.inkSoft)
                            .frame(width: 26)
                        Text("サインアウト")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ink)
                        Spacer()
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("通知").sectionLabel()

            row(
                icon: "bell",
                title: "近くのしおりの通知",
                detail: hasProximityAlerts ? "オン" : "オフ（iOSの設定から変更できます）"
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("データ").sectionLabel()

            VStack(spacing: 0) {
                Button {
                    exportData()
                } label: {
                    rowContent(
                        icon: "square.and.arrow.up",
                        title: "データを書き出す",
                        detail: "しおりとフォロー情報をJSONで保存します"
                    )
                }
                .buttonStyle(.plain)

                if let exportURL {
                    Divider().padding(.leading, 52)
                    ShareLink(item: exportURL) {
                        rowContent(
                            icon: "doc.badge.arrow.up",
                            title: "書き出したファイルを共有",
                            detail: exportURL.lastPathComponent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("アカウント").sectionLabel()

            Button {
                isConfirmingDeletion = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                        .frame(width: 26)
                    Text("アカウントを削除")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
            }
            .buttonStyle(.plain)
        }
    }

    private func row(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(icon: icon, title: title, detail: detail)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
        }
        .buttonStyle(.plain)
    }

    private func rowContent(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.moss)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.inkSoft)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.lock)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private func exportData() {
        let payload = ExportPayload(
            exportedAt: .now,
            bookmarks: store.mine,
            following: Array(social.following).sorted()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let url = FileManager.default.temporaryDirectory.appending(path: "placery-export.json")
        do {
            try encoder.encode(payload).write(to: url, options: .atomic)
            exportURL = url
        } catch {
            exportFailed = true
        }
    }

    private func deleteAccount() async {
        await cloud.deleteMyData(bookmarks: store.mine)
        store.removeAllLocalData()
        social.removeAllLocalData()
        exportURL = nil
        hasProximityAlerts = false
        hasSeenOnboarding = false
        auth.signOut()
    }
}

private struct ExportPayload: Encodable {
    var exportedAt: Date
    var bookmarks: [Bookmark]
    var following: [String]
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(BookmarkStore())
            .environment(SocialStore())
            .environment(SubscriptionStore())
    }
}
