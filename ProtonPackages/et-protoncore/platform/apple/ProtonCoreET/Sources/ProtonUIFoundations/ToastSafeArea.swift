// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct ToastSafeAreaModifier: ViewModifier {
    @EnvironmentObject private var store: ToastStateStore
    @State private var owner = UUID()

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.safeAreaInsets.bottom, initial: true) { _, inset in
                            store.setBottomSafeArea(inset, for: owner)
                        }
                        .onAppear {
                            store.setBottomSafeArea(geometry.safeAreaInsets.bottom, for: owner)
                        }
                }
            }
            .onDisappear { store.removeBottomSafeArea(for: owner) }
    }
}

extension View {
    /// Keeps the scene's toast overlay above this content's bottom safe area.
    public func trackBottomSafeAreaForToast() -> some View {
        modifier(ToastSafeAreaModifier())
    }
}
