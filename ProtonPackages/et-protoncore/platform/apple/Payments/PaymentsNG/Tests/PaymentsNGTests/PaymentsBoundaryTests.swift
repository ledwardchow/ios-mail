// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@testable import PaymentsNG

final class PaymentsBoundaryTests: XCTestCase {
    func testTransactionObserverFailsExplicitly() async {
        do {
            try await TransactionsObserver.shared.start()
            XCTFail("Community build must not pretend to observe StoreKit transactions")
        } catch {
            XCTAssertTrue(error is CommunityPaymentsUnavailable)
            XCTAssertTrue(error.localizedDescription.contains("unavailable"))
        }
    }
    func testNoFabricatedTransactionLog() {
        XCTAssertNil(TransactionsObserver.shared.generateTransactionLog())
    }
}
