import Observation
import StoreKit

@MainActor
@Observable
final class SubscriptionStore {
    enum Plan: String, CaseIterable {
        case monthly = "com.yutamizutani.placery.plus.monthly"
        case yearly = "com.yutamizutani.placery.plus.yearly"
    }

    private(set) var products: [Product] = []
    private(set) var isPlus = false
    private(set) var isLoading = false
    var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let fetched = (try? await Product.products(for: Plan.allCases.map(\.rawValue))) ?? []
        products = fetched.sorted { $0.price < $1.price }

        await refreshEntitlement()
        listenForUpdates()
    }

    func purchase(_ product: Product) async {
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "購入を完了できませんでした。通信状況を確認して、もう一度お試しください。"
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func refreshEntitlement() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if Plan(rawValue: transaction.productID) != nil, transaction.revocationDate == nil {
                active = true
            }
        }
        isPlus = active
    }

    private func listenForUpdates() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlement()
            }
        }
    }
}

extension Product {
    var periodLabel: String {
        guard let period = subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .month: return period.value == 1 ? "月" : "\(period.value)か月"
        case .year: return period.value == 1 ? "年" : "\(period.value)年"
        case .week: return "週"
        case .day: return "日"
        @unknown default: return ""
        }
    }
}
