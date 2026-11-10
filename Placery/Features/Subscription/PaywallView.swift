import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    header
                    benefits
                    plans
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(Color.pageBackground)
            .safeAreaInset(edge: .bottom) { purchaseBar }
            .navigationTitle("Placery Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("復元") {
                        Task { await subscription.restore() }
                    }
                    .font(.system(size: 13))
                }
            }
            .task {
                if subscription.products.isEmpty {
                    await subscription.load()
                }
                selected = subscription.products.first
            }
            .alert("購入できませんでした", isPresented: errorBinding) {
                Button("OK") { subscription.purchaseError = nil }
            } message: {
                Text(subscription.purchaseError ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { subscription.purchaseError != nil },
            set: { if !$0 { subscription.purchaseError = nil } }
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.mossDeep)
            Text("しおりを、好きなだけ。")
                .font(.mincho(24, bold: true))
                .foregroundStyle(Color.ink)
            Text("無料プランでは1か月に\(BookmarkStore.freeMonthlyLimit)枚までしおりを挟めます。")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    private var benefits: some View {
        VStack(spacing: 0) {
            benefitRow(icon: "infinity", title: "しおりが無制限", detail: "1か月の枚数制限がなくなります")
            Divider().padding(.leading, 52)
            benefitRow(icon: "photo.on.rectangle", title: "写真を複数枚", detail: "1枚のしおりに何枚でも添えられます")
            Divider().padding(.leading, 52)
            benefitRow(icon: "square.and.arrow.down", title: "高画質で保存", detail: "写真を圧縮せずに保管します")
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.surface))
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.moss)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
        }
        .padding(14)
    }

    @ViewBuilder
    private var plans: some View {
        if subscription.isPlus {
            Label("Plusを利用中です", systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.mossDeep)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.mossTint))
        } else if subscription.products.isEmpty {
            VStack(spacing: 8) {
                if subscription.isLoading {
                    ProgressView()
                } else {
                    Text("プランを読み込めませんでした")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Text("通信状況を確認して、画面を開き直してください。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.inkSoft)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.surface))
        } else {
            VStack(spacing: 10) {
                ForEach(subscription.products, id: \.id) { product in
                    planCard(product)
                }
            }
        }
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selected?.id == product.id

        return Button {
            selected = product
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(isSelected ? Color.moss : Color.lock)

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Text("\(product.displayPrice) / \(product.periodLabel)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkSoft)
                }

                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.moss : Color.hairline, lineWidth: isSelected ? 2 : 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var purchaseBar: some View {
        if !subscription.isPlus {
            VStack(spacing: 8) {
                Button {
                    guard let selected else { return }
                    Task { await subscription.purchase(selected) }
                } label: {
                    Text("このプランではじめる")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(Color.mossDeep)
                .disabled(selected == nil)

                Text("いつでも解約できます。解約しても、挟んだしおりは残ります。")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.inkSoft)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionStore())
}
