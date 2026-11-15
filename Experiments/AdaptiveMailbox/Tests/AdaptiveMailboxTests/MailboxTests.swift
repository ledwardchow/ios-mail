// SPDX-License-Identifier: GPL-3.0-or-later
import Testing
@testable import AdaptiveMailbox

@Test(arguments: [0.0, 320, 390, 639.9, -1, Double.nan, Double.infinity])
func compactWidths(_ width: Double) { #expect(MailboxLayout.resolve(width: width) == .compact) }
@Test(arguments: [640.0, 669, 820, 1024, 1179.9])
func expandedWidths(_ width: Double) { #expect(MailboxLayout.resolve(width: width) == .expanded) }
@Test(arguments: [1180.0, 1366, 2000])
func sidebarWidths(_ width: Double) { #expect(MailboxLayout.resolve(width: width) == .sidebar) }
@Test func accessibilityUsesOneColumn() { #expect(MailboxLayout.resolve(width: 1500, accessibilityText: true) == .compact) }

@MainActor @Test func resizingPreservesSelectionAndDraft() {
    let session = MailboxSession()
    session.select("weekend")
    session.compose()
    session.draft = "Keep this unfinished draft"
    for width in [390.0, 820, 1366, 500, 820, 390] {
        _ = MailboxLayout.resolve(width: width)
        #expect(session.selectedMessageID == "weekend")
        #expect(session.draft == "Keep this unfinished draft")
        #expect(session.isComposerPresented)
    }
}
@MainActor @Test func closeAndReopenKeepsDraft() {
    let session = MailboxSession()
    session.compose(); session.draft = "Unsent"
    session.closeComposer(); session.compose()
    #expect(session.draft == "Unsent")
    #expect(session.isComposerPresented)
}
@MainActor @Test func discardIsExplicit() {
    let session = MailboxSession()
    session.compose(); session.draft = "Remove me"; session.discardDraft()
    #expect(session.draft.isEmpty)
    #expect(!session.isComposerPresented)
}
@MainActor @Test func folderChangeClearsSelectionNotDraft() {
    let session = MailboxSession()
    session.select("welcome"); session.draft = "Saved in memory"
    session.openFolder("Archive")
    #expect(session.selectedMessage == nil)
    #expect(session.visibleMessages.map(\.id) == ["archive"])
    #expect(session.draft == "Saved in memory")
}
@MainActor @Test func sameFolderPreservesSelection() {
    let session = MailboxSession(); session.select("welcome"); session.openFolder("Inbox")
    #expect(session.selectedMessageID == "welcome")
}
@MainActor @Test func invalidSelectionCannotOpenAnotherFolder() {
    let session = MailboxSession(); session.select("archive")
    #expect(session.selectedMessage == nil)
}
@MainActor @Test func backClearsSelection() {
    let session = MailboxSession(); session.select("welcome"); session.select(nil)
    #expect(session.selectedMessage == nil)
}
