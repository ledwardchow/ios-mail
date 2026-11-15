// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

@main
struct AdaptiveMailboxApp: App {
    @State private var session = MailboxSession()
    var body: some Scene {
        WindowGroup { AdaptiveMailboxView(session: session) }
    }
}
