import Combine
// SPDX-License-Identifier: GPL-3.0-or-later
// Community build: commercial operations are explicitly unavailable. These
// compatibility types do not create purchases, transactions or entitlements.
import Foundation
import StoreKit
import proton_app_uniffi

public struct CommunityPaymentsUnavailable: LocalizedError {
    public init() {}
    public var errorDescription: String? {
        "In-app purchases are unavailable in this community build. Manage your subscription using Proton’s official app or website. Existing account entitlements are unchanged."
    }
}
public enum ProtonPlansManagerError: Error { case transactionCancelledByUser, transactionUnknownError }
public struct DescriptionEntitlement: Hashable, Sendable {
    public enum Kind: Hashable, Sendable { case empty }
    public let type: Kind
    public let text: String
    public let iconName: String
    public let hint: String?
    public init(type: Kind, text: String, iconName: String, hint: String?) {
        self.type = type
        self.text = text
        self.iconName = iconName
        self.hint = hint
    }
}
public enum Entitlement: Hashable, Sendable {
    case description(DescriptionEntitlement)
    case unsupported
}
public struct Decoration: Hashable, Sendable {}
public struct Price: Hashable, Sendable {
    public let current: Int
    public let currency: String
    public let id: String
    public init(current: Int, currency: String, id: String) {
        self.current = current
        self.currency = currency
        self.id = id
    }
}
public struct Vendor: Hashable, Sendable {
    public let productID: String?
    public let customerID: String?
    public init(productID: String?, customerID: String?) {
        self.productID = productID
        self.customerID = customerID
    }
}
public struct Vendors: Hashable, Sendable {
    public let apple: Vendor?
    public init(apple: Vendor?) { self.apple = apple }
}
public struct PlanInstance: Hashable, Sendable {
    public let price: [Price]
    public let description: String
    public let cycle: Int
    public let periodEnd: Int
    public let vendors: Vendors
    public init(price: [Price], description: String, cycle: Int, periodEnd: Int, vendors: Vendors) {
        self.price = price
        self.description = description
        self.cycle = cycle
        self.periodEnd = periodEnd
        self.vendors = vendors
    }
}
public struct AvailablePlan: Hashable, Sendable {
    public let description: String
    public let instances: [PlanInstance]
    public let name: String?
    public let state: Int
    public let type: Int
    public let title: String
    public let features: Int
    public let entitlements: [Entitlement]
    public let decorations: [Decoration]
    public let id: String
    public let services: Int
    public init(
        description: String, instances: [PlanInstance], name: String?, state: Int, type: Int, title: String, features: Int, entitlements: [Entitlement], decorations: [Decoration], id: String,
        services: Int,
    ) {
        self.description = description
        self.instances = instances
        self.name = name
        self.state = state
        self.type = type
        self.title = title
        self.features = features
        self.entitlements = entitlements
        self.decorations = decorations
        self.id = id
        self.services = services
    }
}
public struct AvailablePlans { public let plans: [AvailablePlan] }
public protocol ProductProtocol {
    var displayName: String { get }
    var description: String { get }
    var price: Decimal { get }
    var priceFormatStyle: Decimal.FormatStyle.Currency { get }
    var id: String { get }
    var subscription: Product.SubscriptionInfo? { get }
    func purchase(options: Set<Product.PurchaseOption>) async throws -> Product.PurchaseResult
}
extension ProductProtocol { public var displayPrice: String { priceFormatStyle.format(price) } }
public struct ComposedPlan {
    public let plan: AvailablePlan
    public let instance: PlanInstance
    public let product: any ProductProtocol
    public init(plan: AvailablePlan, instance: PlanInstance, product: any ProductProtocol) {
        self.plan = plan
        self.instance = instance
        self.product = product
    }
    public var storePricePerMonth: Decimal { instance.cycle > 0 ? product.price / Decimal(instance.cycle) : product.price }
    public var pricePerMonthLabel: String { product.priceFormatStyle.format(storePricePerMonth) }
    public func discount(comparedTo other: ComposedPlan) -> Int? {
        guard other.storePricePerMonth > 0 else { return nil }
        let value = min(99, Int(NSDecimalNumber(decimal: (1 - storePricePerMonth / other.storePricePerMonth) * 100).doubleValue.rounded()))
        return value >= 5 ? value : nil
    }
}
public struct CurrentSubscriptionResponse {
    public let name: String?
    public let cycle: Int?
}
public protocol RemoteManagerProviding {}
public protocol PlansComposerProviding {
    var hasData: Bool { get }
    func getStoreProducts(_ plans: [String]) async throws -> [Product]
    func fetchProtonPlans() async throws -> AvailablePlans
    func matchPlanToStoreProduct(_ productId: String) -> ComposedPlan?
    func fetchAvailablePlans() async throws -> [ComposedPlan]
    func updateRemoteManager(remoteManager: any RemoteManagerProviding)
    func fetchCurrentSubscription() async throws -> CurrentSubscriptionResponse
}
public final class PlansComposerRust: PlansComposerProviding {
    public init(rustSession: MailUserSession) {}
    public var hasData: Bool { false }
    public func getStoreProducts(_ plans: [String]) async throws -> [Product] { throw CommunityPaymentsUnavailable() }
    public func fetchProtonPlans() async throws -> AvailablePlans { throw CommunityPaymentsUnavailable() }
    public func matchPlanToStoreProduct(_ productId: String) -> ComposedPlan? { nil }
    public func fetchAvailablePlans() async throws -> [ComposedPlan] { throw CommunityPaymentsUnavailable() }
    public func updateRemoteManager(remoteManager: any RemoteManagerProviding) {}
    public func fetchCurrentSubscription() async throws -> CurrentSubscriptionResponse { throw CommunityPaymentsUnavailable() }
}
public final class ProtonPlansManager {
    public init(rustSession: MailUserSession) {}
    public init(plansComposer: any PlansComposerProviding, rustSession: MailUserSession) {}
    public func purchase(productId: String) async throws { throw CommunityPaymentsUnavailable() }
    public func getCurrentPlan() async throws -> CurrentSubscriptionResponse { throw CommunityPaymentsUnavailable() }
}
public struct TransactionsObserverConfiguration {
    public let rustSession: MailUserSession
    public init(rustSession: MailUserSession) { self.rustSession = rustSession }
}
public protocol TransactionsObserverProviding {
    func start() async throws
    func stop()
    func setConfiguration(_ configuration: TransactionsObserverConfiguration)
    func addTransactionInProgress(_ transactionId: UInt64)
    func removeTransactionInProgress(_ transactionId: UInt64)
    func generateTransactionLog() -> URL?
    func deleteLogs() async
}
public final class TransactionsObserver: TransactionsObserverProviding {
    public static let shared = TransactionsObserver()
    public func start() async throws { throw CommunityPaymentsUnavailable() }
    public func stop() {}
    public func setConfiguration(_ configuration: TransactionsObserverConfiguration) {}
    public func addTransactionInProgress(_ transactionId: UInt64) {}
    public func removeTransactionInProgress(_ transactionId: UInt64) {}
    public func generateTransactionLog() -> URL? { nil }
    public func deleteLogs() async {}
}
