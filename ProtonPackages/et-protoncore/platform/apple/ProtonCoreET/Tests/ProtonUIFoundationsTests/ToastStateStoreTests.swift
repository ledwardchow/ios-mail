// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest
@testable import ProtonUIFoundations

final class ToastStateStoreTests: XCTestCase {
    func testDismissReconstructedEqualContentWithDifferentID() {
        let store = ToastStateStore()
        let original = Toast.information(message: "Draft saved")
        let reconstructed = Toast.information(message: "Draft saved")
        XCTAssertNotEqual(original.id, reconstructed.id)
        store.present(toast: original)
        store.dismiss(toast: reconstructed)
        XCTAssertTrue(store.state.toasts.isEmpty)
    }

    func testDismissByIDOnlyRemovesExactPresentation() {
        let store = ToastStateStore()
        let first = Toast.information(message: "Draft saved")
        let second = Toast.information(message: "Draft saved")
        store.present(toast: first)
        store.present(toast: second)
        store.dismiss(withID: first.id)
        XCTAssertEqual(store.state.toasts.map(\.id), [second.id])
        store.dismiss(withID: UUID())
        XCTAssertEqual(store.state.toasts.map(\.id), [second.id])
    }

    func testDismissByIDResetsHeightOnlyWhenEmpty() {
        let store = ToastStateStore()
        let first = Toast.information(message: "First")
        let second = Toast.information(message: "Second")
        store.present(toast: first)
        store.present(toast: second)
        store.setHeight(96)
        store.dismiss(withID: first.id)
        XCTAssertEqual(store.state.maxToastHeight, 96)
        store.dismiss(withID: second.id)
        XCTAssertTrue(store.state.toasts.isEmpty)
        XCTAssertEqual(store.state.maxToastHeight, 0)
    }

    func testDismissByContentResetsHeightWhenEmpty() {
        let store = ToastStateStore()
        store.present(toast: .information(message: "Draft saved"))
        store.setHeight(64)
        store.dismiss(toast: .information(message: "Draft saved"))
        XCTAssertTrue(store.state.toasts.isEmpty)
        XCTAssertEqual(store.state.maxToastHeight, 0)
    }

    func testRepeatedPresentationWithSameIDReplacesWithoutDuplicate() {
        let store = ToastStateStore()
        let id = UUID()
        let original = Toast(id: id, message: "Sending", style: .information)
        let updated = Toast(id: id, message: "Sent", style: .success)
        store.present(toast: original)
        store.present(toast: original)
        XCTAssertEqual(store.state.toasts.count, 1)
        store.present(toast: updated)
        XCTAssertEqual(store.state.toasts.count, 1)
        XCTAssertEqual(store.state.toasts.first?.id, id)
        XCTAssertEqual(store.state.toasts.first?.message, "Sent")
        XCTAssertEqual(store.state.toasts.first?.style, .success)
    }
    func testBottomSafeAreaTracksLargestActiveOwnerAndCleansUp() {
        let store = ToastStateStore()
        let mailbox = UUID()
        let conversation = UUID()
        store.setBottomSafeArea(34, for: mailbox)
        store.setBottomSafeArea(83, for: conversation)
        XCTAssertEqual(store.state.bottomSafeArea, 83)
        store.removeBottomSafeArea(for: conversation)
        XCTAssertEqual(store.state.bottomSafeArea, 34)
        store.removeBottomSafeArea(for: mailbox)
        XCTAssertEqual(store.state.bottomSafeArea, 0)
    }

    func testBottomSafeAreaUpdatesForLayoutAndRejectsInvalidInsets() {
        let store = ToastStateStore()
        let owner = UUID()
        store.setBottomSafeArea(83, for: owner)
        store.setBottomSafeArea(300, for: owner)
        XCTAssertEqual(store.state.bottomSafeArea, 300)
        store.setBottomSafeArea(-10, for: owner)
        XCTAssertEqual(store.state.bottomSafeArea, 0)
        store.setBottomSafeArea(.infinity, for: owner)
        XCTAssertEqual(store.state.bottomSafeArea, 0)
    }

}
