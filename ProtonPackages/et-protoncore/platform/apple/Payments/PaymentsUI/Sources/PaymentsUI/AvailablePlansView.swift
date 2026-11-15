import Combine
import PaymentsNG
// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import proton_app_uniffi

public enum PresentationMode { case push, modal }
public enum TransactionProgress: Equatable { case transactionCompleted }
@MainActor public final class AvailablePlansViewModel: ObservableObject {
    // No transaction events can be emitted in this community adapter.
    public let transactionProgress = Empty<TransactionProgress, Never>(completeImmediately: false)
    public init(appVersion: String, presentationMode: PresentationMode, rustSession: MailUserSession) {}
}
public struct AvailablePlansView: View {
    @ObservedObject var viewModel: AvailablePlansViewModel
    public init(viewModel: AvailablePlansViewModel) { self.viewModel = viewModel }
    public var body: some View {
        ContentUnavailableView("Purchases unavailable", systemImage: "creditcard.trianglebadge.exclamationmark", description: Text(CommunityPaymentsUnavailable().localizedDescription))
            .navigationTitle("Subscription")
    }
}
