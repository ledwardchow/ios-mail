// SPDX-License-Identifier: GPL-3.0-or-later
// Public-build compatibility implementation. No proprietary Proton source used.
import Combine
import Foundation

extension ProcessInfo {
    public static var isRunningSwiftUIPreviews: Bool {
        processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

/// Relays the nested model's changes to its owning ObservableObject.
@propertyWrapper
public struct NestedObservableObject<Value: ObservableObject> {
    private var value: Value
    private var subscription: AnyCancellable?
    public init(wrappedValue: Value) { value = wrappedValue }
    @available(*, unavailable, message: "Use on an ObservableObject property")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
    public static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>,
    ) -> Value where Owner.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            if owner[keyPath: storageKeyPath].subscription == nil {
                owner[keyPath: storageKeyPath].subscription = owner[keyPath: storageKeyPath].value.objectWillChange.sink { [weak owner] _ in owner?.objectWillChange.send() }
            }
            return owner[keyPath: storageKeyPath].value
        }
        set {
            owner.objectWillChange.send()
            owner[keyPath: storageKeyPath].subscription = newValue.objectWillChange.sink { [weak owner] _ in owner?.objectWillChange.send() }
            owner[keyPath: storageKeyPath].value = newValue
        }
    }
}
