// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest
@testable import InboxCore

final class ProtonAPIErrorCodeTests: XCTestCase {
    func testReadsExplicitJSONCode() {
        XCTAssertEqual(ProtonAPIErrorCode.parse(#"{"Code":2501,"Error":"Label does not exist"}"#), 2501)
        XCTAssertEqual(ProtonAPIErrorCode.parse(#"{"Code":2503,"Error":"Operation timed out"}"#), 2503)
    }

    func testReadsPublicSDKStructuredDebugAndDisplayFormats() {
        XCTAssertEqual(ProtonAPIErrorCode.parse(#"Some(ApiErrorInfo { code: 2501, error: Some("Missing"), details: None })"#), 2501)
        XCTAssertEqual(ProtonAPIErrorCode.parse(#"2501: Some("Missing") (None)"#), 2501)
        XCTAssertEqual(ProtonAPIErrorCode.parse("2501: None (None)"), 2501)
    }

    func testUnknownAndHTTPStatusDoNotBecomeAPICodes() {
        for payload in ["HTTP 404", "404", "None", "request failed: 2501", "2501: Some(garbage)",
                        #"{"Error":"Code: 2501"}"#, #"{"Code":"2501"}"#, #"{"Code":4294967296}"#] {
            XCTAssertNil(ProtonAPIErrorCode.parse(payload), payload)
        }
    }
}
