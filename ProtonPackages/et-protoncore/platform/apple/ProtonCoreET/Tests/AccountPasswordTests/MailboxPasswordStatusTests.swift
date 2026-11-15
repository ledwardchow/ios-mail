// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest
@testable import AccountPassword

final class MailboxPasswordStatusTests: XCTestCase {
    func testSinglePasswordIsExplicitlyFalse() {
        XCTAssertEqual(MailboxPasswordStatus.decode(mode: 1), false)
    }
    func testTwoPasswordModeIsExplicitlyTrue() {
        XCTAssertEqual(MailboxPasswordStatus.decode(mode: 2), true)
    }
    func testUnknownModeNeverPretendsToBeSinglePassword() {
        for mode: UInt32 in [0, 3, 255, .max] {
            XCTAssertNil(MailboxPasswordStatus.decode(mode: mode))
        }
    }
}
