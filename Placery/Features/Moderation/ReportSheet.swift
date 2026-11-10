import SwiftUI

struct ReportSheet: View {
    var bookmark: Bookmark

    @Environment(SocialStore.self) private var social
    @Environment(CloudSyncService.self) private var cloud
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var reason: Report.Reason = .inappropriate
    @State private var detail = ""
    @State private var isSent = false

    var body: some View {
        NavigationStack {
            Group {
                if isSent {
                    sentState
                } else {
                    form
                }
            }
            .navigationTitle("このしおりを通報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("@\(bookmark.author) さんの「\(bookmark.placeName)」を通報します。内容を確認し、必要に応じて削除などの対応を行います。")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSoft)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 9) {
                    Text("理由").sectionLabel()
                    VStack(spacing: 0) {
                        ForEach(Report.Reason.allCases) { option in
                            Button {
                                reason = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.ink)
                                    Spacer()
                                    if reason == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Color.moss)
                                    }
                                }
                                .padding(.vertical, 13)
                                .padding(.horizontal, 14)
                            }
                            .buttonStyle(.plain)

                            if option != Report.Reason.allCases.last {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("詳細（任意）").sectionLabel()
                    TextField("状況を教えてください", text: $detail, axis: .vertical)
                        .font(.system(size: 13))
                        .frame(minHeight: 80, alignment: .topLeading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.field))
                }

                Button {
                    let report = social.report(bookmark, reason: reason, detail: detail)
                    withAnimation { isSent = true }
                    Task {
                        if await cloud.submitReport(report, reporterID: auth.userID) {
                            social.markReportSynced(report.id)
                        }
                    }
                } label: {
                    Text("通報する")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(Color.mossDeep)
            }
            .padding(20)
        }
        .background(Color.pageBackground)
    }

    private var sentState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.moss)
            Text("通報を受け付けました")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.ink)
            Text("内容を確認し、ガイドラインに違反している場合は削除などの対応を行います。\n@\(bookmark.author) さんをブロックすると、今後このアカウントのしおりは表示されません。")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            Button("@\(bookmark.author) をブロックする") {
                social.block(bookmark.author)
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .foregroundStyle(Color.ink)
            .padding(.top, 6)

            Button("閉じる") { dismiss() }
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSoft)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground)
    }
}

#Preview {
    ReportSheet(bookmark: Bookmark.samples[0])
        .environment(SocialStore())
}
