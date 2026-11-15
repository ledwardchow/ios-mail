// SPDX-License-Identifier: GPL-3.0-or-later
// Public-build compatibility implementation; no private UI source or assets.
import SwiftUI

public struct Toast: Identifiable, Hashable {
    public enum Style: Hashable { case information, success, warning, error }
    public enum Duration: Hashable {
        case short, medium, long
        case custom(TimeInterval)
        public var timeInterval: TimeInterval {
            switch self {
            case .short: 3
            case .medium: 5
            case .long: 8
            case .custom(let value): max(0, value)
            }
        }
    }
    public struct Button {
        public enum Content: Hashable { case title(String) }
        public enum ButtonType: Hashable {
            case smallTrailing(content: Content)
            case largeBottom(content: Content)
        }
        public let type: ButtonType
        public let action: () async -> Void
        public init(type: ButtonType, action: @escaping () async -> Void) {
            self.type = type
            self.action = action
        }
        var title: String {
            switch type {
            case .smallTrailing(let content), .largeBottom(let content):
                switch content {
                case .title(let title): title
                }
            }
        }
    }
    public let id: UUID
    public let title: String?
    public let message: String
    public let button: Button?
    public let style: Style
    public let duration: Duration
    public init(id: UUID = UUID(), title: String? = nil, message: String, button: Button? = nil, style: Style, duration: Duration = .short) {
        self.id = id
        self.title = title
        self.message = message
        self.button = button
        self.style = style
        self.duration = duration
    }
    // Equality describes visible content, while id identifies a presentation.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message && lhs.style == rhs.style && lhs.duration == rhs.duration && lhs.button?.type == rhs.button?.type
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(style)
        hasher.combine(duration)
        hasher.combine(button?.type)
    }
    public static func information(message: String, duration: Duration = .short) -> Self { .init(message: message, style: .information, duration: duration) }
    public static func error(message: String, duration: Duration = .short) -> Self { .init(message: message, style: .error, duration: duration) }
    public static func warning(message: String, duration: Duration = .short) -> Self { .init(message: message, style: .warning, duration: duration) }
    public static func success(message: String, duration: Duration = .short) -> Self { .init(message: message, style: .success, duration: duration) }
}
public struct ToastState: Equatable {
    public var toasts: [Toast] = []
    public var maxToastHeight: CGFloat = 0
    public var bottomSafeArea: CGFloat = 0
    public static var initial: Self { .init() }
    public init() {}
}
public final class ToastStateStore: ObservableObject {
    @Published public private(set) var state: ToastState
    private var bottomSafeAreas: [UUID: CGFloat] = [:]
    public init(initialState: ToastState = .initial) { state = initialState }
    public func present(toast: Toast) {
        state.toasts.removeAll { $0.id == toast.id }
        state.toasts.append(toast)
    }
    public func dismiss(toast: Toast) {
        state.toasts.removeAll { $0.id == toast.id || $0 == toast }
        if state.toasts.isEmpty { state.maxToastHeight = 0 }
    }
    public func dismiss(withID id: UUID) {
        state.toasts.removeAll { $0.id == id }
        if state.toasts.isEmpty { state.maxToastHeight = 0 }
    }
    public func setBottomSafeArea(_ inset: CGFloat, for owner: UUID) {
        bottomSafeAreas[owner] = inset.isFinite ? max(0, inset) : 0
        updateBottomSafeArea()
    }
    public func removeBottomSafeArea(for owner: UUID) {
        bottomSafeAreas.removeValue(forKey: owner)
        updateBottomSafeArea()
    }
    private func updateBottomSafeArea() {
        let inset = bottomSafeAreas.values.max() ?? 0
        if state.bottomSafeArea != inset { state.bottomSafeArea = inset }
    }
    public func setHeight(_ height: CGFloat) { if state.maxToastHeight != height { state.maxToastHeight = height } }
}
extension Animation { public static var toastAnimation: Animation { .easeInOut(duration: 0.25) } }
public struct ToastView: View {
    let model: Toast
    let didSwipeDown: () -> Void
    public init(model: Toast, didSwipeDown: @escaping () -> Void) {
        self.model = model
        self.didSwipeDown = didSwipeDown
    }
    private var color: Color {
        switch model.style {
        case .information: .indigo
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.style == .error ? "exclamationmark.circle.fill" : "info.circle.fill").foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                if let title = model.title { Text(title).bold() }
                Text(model.message)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let button = model.button {
                SwiftUI.Button(button.title) {
                    Task {
                        await button.action()
                        didSwipeDown()
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .padding().background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(radius: 3).gesture(DragGesture().onEnded { if $0.translation.height > 25 { didSwipeDown() } })
        .accessibilityElement(children: .contain)
    }
}
private struct ToastHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
public struct ToastSceneView: View {
    @EnvironmentObject private var store: ToastStateStore
    let dispatchAfter: (DispatchTime, DispatchWorkItem) -> Void
    public init(dispatchAfter: @escaping (DispatchTime, DispatchWorkItem) -> Void) { self.dispatchAfter = dispatchAfter }
    public var body: some View {
        GeometryReader { sceneGeometry in
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    ForEach(store.state.toasts) { toast in
                        ToastView(model: toast) { store.dismiss(withID: toast.id) }
                            .onAppear {
                                dispatchAfter(.now() + toast.duration.timeInterval, DispatchWorkItem { store.dismiss(withID: toast.id) })
                            }
                    }
                }
                .background(GeometryReader { proxy in Color.clear.preference(key: ToastHeightKey.self, value: proxy.size.height) })
            }
            .padding(.horizontal, 16)
            // The overlay window already respects its own home-indicator inset.
            // Add only the extra exclusion area reported by the active content,
            // such as a bottom navigation toolbar or the software keyboard.
            .padding(.bottom, 8 + max(0, store.state.bottomSafeArea - sceneGeometry.safeAreaInsets.bottom))
            .onPreferenceChange(ToastHeightKey.self) { store.setHeight($0) }
            .animation(.toastAnimation, value: store.state.toasts)
            .animation(.toastAnimation, value: store.state.bottomSafeArea)
        }
    }
}

public extension Toast {
    static var comingSoon: Toast { .information(message: "This action is not available in this build.") }
}
