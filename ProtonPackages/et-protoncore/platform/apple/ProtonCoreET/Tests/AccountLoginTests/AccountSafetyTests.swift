import AccountChallenge
// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest
import proton_app_uniffi

@testable import AccountLogin

final class AccountSafetyTests: XCTestCase {
    @MainActor
    func testPreviewCoordinatorCannotExposeOrCreateAnAuthenticatedSession() {
        let preview = AccountAuthCoordinator.mock()
        preview.refresh()
        XCTAssertNil(preview.appContext)
        XCTAssertNil(preview.primaryAccountSignedInSession())
        XCTAssertTrue(preview.accounts.isEmpty)
    }

    func testUnsupportedHumanVerificationCancelsInsteadOfReturningAToken() async {
        let coordinator = AccountChallengeCoordinator(
            apiConfig: .init(userAgent: "OfflineRegressionTest", envId: .prod, proxy: nil, resolver: nil),
            appDetails: .init(platform: "ios", product: "mail", version: "test"),
        )
        // Sentinel objects have no Rust backing: touching or forwarding them to the SDK
        // would fail. The cancellation path must not inspect or transmit challenge data.
        let response = await coordinator.onChallenge(
            server: ChallengeServer(noPointer: .init()),
            payload: ChallengePayload(noPointer: .init()),
        )
        guard case .cancelled = response else {
            return XCTFail("Unsupported human verification must never be reported as successful.")
        }
    }
}
