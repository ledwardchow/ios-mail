// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Observation

public enum MailboxLayout: Equatable, Sendable {
    case compact, expanded, sidebar

    /// Available window width, not device name or screen bounds. Extra-large
    /// accessibility text deliberately falls back to a single readable column.
    public static func resolve(width: Double, accessibilityText: Bool = false) -> Self {
        guard width.isFinite, !accessibilityText else { return .compact }
        if width >= 1180 { return .sidebar }
        if width >= 640 { return .expanded }
        return .compact
    }
}

public struct DemoMessage: Identifiable, Equatable, Sendable {
    public let id: String
    public let sender: String
    public let subject: String
    public let body: String
    public let folder: String

    public static let samples: [Self] = [
        .init(id: "welcome", sender: "Layout lab", subject: "One inbox, two views", body: "This is a local-only layout experiment. Widen the window to keep the mailbox beside this message. No account is connected and no email is sent.", folder: "Inbox"),
        .init(id: "weekend", sender: "Sample sender", subject: "Weekend plans", body: "Selection survives a narrower window. Try composing a draft, resizing, closing it, and opening it again.", folder: "Inbox"),
        .init(id: "archive", sender: "Layout lab", subject: "Archived sample", body: "Changing folders clears the selected message without discarding your unsent draft.", folder: "Archive")
    ]
}

@MainActor @Observable
public final class MailboxSession {
    public private(set) var selectedMessageID: String?
    public private(set) var folder = "Inbox"
    public var draft = ""
    public var isComposerPresented = false
    public let messages: [DemoMessage]

    public init(messages: [DemoMessage] = DemoMessage.samples) { self.messages = messages }
    public var visibleMessages: [DemoMessage] { messages.filter { $0.folder == folder } }
    public var selectedMessage: DemoMessage? { visibleMessages.first { $0.id == selectedMessageID } }

    public func select(_ id: String?) {
        selectedMessageID = visibleMessages.first { $0.id == id }?.id
    }
    public func openFolder(_ name: String) {
        guard name != folder else { return }
        folder = name
        selectedMessageID = nil
    }
    public func compose() { isComposerPresented = true }
    public func closeComposer() { isComposerPresented = false }
    public func discardDraft() { draft = ""; isComposerPresented = false }
}
