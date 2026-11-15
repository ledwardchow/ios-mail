// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

@MainActor
public struct AdaptiveMailboxView: View {
    @Bindable private var session: MailboxSession
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var foldersPresented = false

    public init(session: MailboxSession) { self.session = session }

    public var body: some View {
        GeometryReader { geometry in
            let layout = MailboxLayout.resolve(width: geometry.size.width, accessibilityText: dynamicTypeSize.isAccessibilitySize)
            HStack(spacing: 0) {
                if layout == .sidebar {
                    folders.frame(width: 220)
                    Divider()
                }
                if layout != .compact || session.selectedMessage == nil {
                    mailbox
                        .frame(maxWidth: layout == .compact ? .infinity : 280)
                    if layout != .compact { Divider() }
                }
                if layout != .compact || session.selectedMessage != nil {
                    detail(compact: layout == .compact)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .accessibilityIdentifier("layout.\(String(describing: layout))")
        }
        // Present outside the width-dependent subtree so resizing does not own
        // or reset composer state. Draft text belongs to the session as well.
        .sheet(isPresented: $session.isComposerPresented) { composer }
        .sheet(isPresented: $foldersPresented) {
            NavigationStack {
                folders.navigationTitle("Folders")
                    .toolbar { Button("Done") { foldersPresented = false } }
            }
        }
        .tint(.purple)
    }

    private var mailbox: some View {
        NavigationStack {
            List(session.visibleMessages) { message in
                Button {
                    session.select(message.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.sender).font(.caption).foregroundStyle(.secondary)
                        Text(message.subject).font(.headline).foregroundStyle(.primary)
                        Text(message.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                    }.padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowBackground(session.selectedMessageID == message.id ? Color.purple.opacity(0.12) : Color.clear)
                .accessibilityIdentifier("message.\(message.id)")
            }
            .listStyle(.plain)
            .navigationTitle(session.folder)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { foldersPresented = true } label: { Label("Folders", systemImage: "folder") }
                        .accessibilityIdentifier("folders")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { session.compose() } label: { Label("Compose", systemImage: "square.and.pencil") }
                        .accessibilityIdentifier("compose")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("LOCAL DEMO · NO ACCOUNT CONNECTED")
                    .font(.caption2).foregroundStyle(.secondary).padding(10)
                    .frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
    }

    private func detail(compact: Bool) -> some View {
        NavigationStack {
            Group {
                if let message = session.selectedMessage {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(message.subject).font(.title.bold())
                            Label(message.sender, systemImage: "person.crop.circle").foregroundStyle(.secondary)
                            Divider()
                            Text(message.body).textSelection(.enabled)
                        }.frame(maxWidth: 680, alignment: .leading).padding(24)
                    }
                    .accessibilityIdentifier("detail.\(message.id)")
                } else {
                    ContentUnavailableView("Choose a message", systemImage: "envelope.open", description: Text("Your mailbox stays alongside your reading pane."))
                }
            }
            .toolbar {
                if compact {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { session.select(nil) } label: { Label("Inbox", systemImage: "chevron.left") }
                            .accessibilityIdentifier("backToInbox")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { session.compose() } label: { Label("Compose", systemImage: "square.and.pencil") }
                        .accessibilityIdentifier("detailCompose")
                }
            }
        }
    }

    private var folders: some View {
        List(["Inbox", "Archive"], id: \.self) { folder in
            Button {
                session.openFolder(folder)
                foldersPresented = false
            } label: { Label(folder, systemImage: folder == "Inbox" ? "tray" : "archivebox") }
                .accessibilityIdentifier("folder.\(folder)")
        }.listStyle(.sidebar)
    }

    private var composer: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Local draft only. Sending is disabled in this prototype.").font(.callout).foregroundStyle(.secondary)
                TextEditor(text: $session.draft).accessibilityIdentifier("draftBody")
            }.padding().navigationTitle("Draft")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { session.closeComposer() }.accessibilityIdentifier("closeDraft")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Discard", role: .destructive) { session.discardDraft() }.accessibilityIdentifier("discardDraft")
                    }
                }
        }
    }
}
