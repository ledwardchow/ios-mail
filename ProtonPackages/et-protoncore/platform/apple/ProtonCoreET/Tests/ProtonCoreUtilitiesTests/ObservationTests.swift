// SPDX-License-Identifier: GPL-3.0-or-later
import Combine
import XCTest

@testable import ProtonCoreUtilities

final class ObservationTests: XCTestCase {
    private final class Child: ObservableObject {
        @Published var count = 0
    }
    private final class Parent: ObservableObject {
        @NestedObservableObject var child: Child
        init(child: Child) { self.child = child }
    }

    func testNestedMutationPublishesOwnerChange() {
        let child = Child()
        let parent = Parent(child: child)
        var changes = 0
        let token = parent.objectWillChange.sink { changes += 1 }
        parent.child.count += 1
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(parent.child.count, 1)
        withExtendedLifetime(token) {}
    }

    func testRepeatedReadsDoNotDuplicateSubscriptions() {
        let parent = Parent(child: Child())
        var changes = 0
        let token = parent.objectWillChange.sink { changes += 1 }
        for _ in 0..<10 { _ = parent.child }
        parent.child.count = 42
        XCTAssertEqual(changes, 1)
        withExtendedLifetime(token) {}
    }

    func testReplacementPublishesAndUnsubscribesOldChild() {
        let oldChild = Child()
        let newChild = Child()
        let parent = Parent(child: oldChild)
        _ = parent.child
        var changes = 0
        let token = parent.objectWillChange.sink { changes += 1 }
        parent.child = newChild
        XCTAssertEqual(changes, 1)
        oldChild.count += 1
        XCTAssertEqual(changes, 1, "The detached model must no longer notify the parent")
        newChild.count += 1
        XCTAssertEqual(changes, 2)
        XCTAssertTrue(parent.child === newChild)
        withExtendedLifetime(token) {}
    }

    func testSubscriptionDoesNotRetainParent() {
        let child = Child()
        weak var weakParent: Parent?
        do {
            let parent = Parent(child: child)
            weakParent = parent
            _ = parent.child
        }
        XCTAssertNil(weakParent)
        child.count += 1
    }

    func testPreviewFlagMatchesAppleEnvironmentVariable() {
        XCTAssertEqual(ProcessInfo.isRunningSwiftUIPreviews, ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1")
    }
}
