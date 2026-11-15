// SPDX-License-Identifier: GPL-3.0-or-later
// Public-build compatibility implementation using native SwiftUI controls.
import SwiftUI
import UIKit

public enum SFSymbol: String {
    case chevronUp = "chevron.up"
    case chevronLeft = "chevron.left"
    case chevronRight = "chevron.right"
    case chevronDown = "chevron.down"
    case square, checkmarkSquare = "checkmark.square"
    case xmark, checkmark, plus, ellipsis
    case arrowUpRightSquare = "arrow.up.right.square"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case xmarkCircleFill = "xmark.circle.fill"
    case forward = "arrowshape.turn.up.right"
    case reply = "arrowshape.turn.up.left"
    case replyAll = "arrowshape.turn.up.left.2"
    case star
    case starFilled = "star.fill"
    case starSlash = "star.slash"
    case infoCircle = "info.circle"
    case sunMax = "sun.max"
    case suitcase, sofa
    case arrowCirclePath = "arrow.trianglehead.2.clockwise.rotate.90"
    case magnifier = "magnifyingglass"
    case chevronUpChevronDown = "chevron.up.chevron.down"
    case minusCircleFill = "minus.circle.fill"
    case plusCircleFill = "plus.circle.fill"
    case arrowClockwise = "arrow.clockwise"
}
extension UIImage { public convenience init?(symbol: SFSymbol) { self.init(systemName: symbol.rawValue) } }
extension Image { public init(symbol: SFSymbol) { self.init(systemName: symbol.rawValue) } }
extension Binding {
    public static func readonly(get: @escaping () -> Value) -> Self { .init(get: get, set: { _ in }) }
}
extension View {
    public func roundedRectangleStyle(cornerRadius: CGFloat = 12) -> some View { clipShape(RoundedRectangle(cornerRadius: cornerRadius)) }
}
public struct DefaultPressedButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View { configuration.label.opacity(configuration.isPressed ? 0.6 : 1) }
}
public struct ForEachEnumerated<Element, ID: Hashable, Content: View>: View {
    private let values: [Element]
    private let id: KeyPath<(offset: Int, element: Element), ID>
    private let content: (Element, Int) -> Content
    public init<C: RandomAccessCollection>(_ values: C, id: KeyPath<(offset: Int, element: Element), ID>, @ViewBuilder content: @escaping (Element, Int) -> Content) where C.Element == Element {
        self.values = Array(values)
        self.id = id
        self.content = content
    }
    public var body: some View { ForEach(Array(values.enumerated()), id: id) { item in content(item.element, item.offset) } }
}
public struct ForEachLast<Element, Content: View>: View {
    private let values: [Element]
    private let content: (Element, Bool) -> Content
    public init<C: RandomAccessCollection>(collection: C, @ViewBuilder content: @escaping (Element, Bool) -> Content) where C.Element == Element {
        values = Array(collection)
        self.content = content
    }
    public var body: some View { ForEach(Array(values.enumerated()), id: \.offset) { item in content(item.element, item.offset == values.count - 1) } }
}
public struct FormSection<Content: View>: View {
    let header: LocalizedStringResource?
    let footer: LocalizedStringResource?
    let content: Content
    public init(header: LocalizedStringResource? = nil, footer: LocalizedStringResource? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let header { Text(header).font(.footnote).foregroundStyle(.secondary) }
            content
            if let footer { Text(footer).font(.footnote).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
public struct FormList<Element, Content: View>: View {
    public enum Style {
        case separator(Separator)
        public enum Separator { case normLeftPadding, fullWidth }
    }
    let values: [Element]
    let style: Style
    let content: (Element) -> Content
    public init<C: RandomAccessCollection>(collection: C, style: Style = .separator(.normLeftPadding), @ViewBuilder content: @escaping (Element) -> Content) where C.Element == Element {
        values = Array(collection)
        self.style = style
        self.content = content
    }
    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { item in
                content(item.element)
                if item.offset < values.count - 1 { Divider().padding(.leading, 16) }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground)).roundedRectangleStyle()
    }
}
public struct FormSwitchView: View {
    let title: LocalizedStringResource
    @Binding var isOn: Bool
    public init(title: LocalizedStringResource, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }
    public var body: some View { Toggle(isOn: $isOn) { Text(title) }.padding().background(Color(uiColor: .secondarySystemGroupedBackground)).roundedRectangleStyle() }
}
public struct FormSmallButton: View {
    let title: LocalizedStringResource
    let rightSymbol: SFSymbol?
    let action: () -> Void
    public init(title: LocalizedStringResource, rightSymbol: SFSymbol? = nil, action: @escaping () -> Void) {
        self.title = title
        self.rightSymbol = rightSymbol
        self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if let rightSymbol { Image(symbol: rightSymbol) }
            }
            .padding().contentShape(Rectangle())
        }
        .buttonStyle(DefaultPressedButtonStyle()).background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}
public struct SecureInput: UIViewRepresentable {
    public struct Configuration {
        public let font: UIFont?
        public let alignment: NSTextAlignment
        public let placeholder: LocalizedStringResource?
        public let keyboardType: UIKeyboardType
        public let allowedCharacters: CharacterSet?
        public init(font: UIFont?, alignment: NSTextAlignment, placeholder: LocalizedStringResource?, keyboardType: UIKeyboardType, allowedCharacters: CharacterSet?) {
            self.font = font
            self.alignment = alignment
            self.placeholder = placeholder
            self.keyboardType = keyboardType
            self.allowedCharacters = allowedCharacters
        }
    }
    let configuration: Configuration
    @Binding var text: String
    @Binding var isSecure: Bool
    public init(configuration: Configuration, text: Binding<String>, isSecure: Binding<Bool>) {
        self.configuration = configuration
        _text = text
        _isSecure = isSecure
    }
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    public func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        return field
    }
    public func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        field.text = text
        field.isSecureTextEntry = isSecure
        field.font = configuration.font ?? .preferredFont(forTextStyle: .body)
        field.textAlignment = configuration.alignment
        field.placeholder = configuration.placeholder.map { String(localized: $0) }
        field.keyboardType = configuration.keyboardType
    }
    public final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SecureInput
        init(_ parent: SecureInput) { self.parent = parent }
        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let allowed = parent.configuration.allowedCharacters else { return true }
            return string.unicodeScalars.allSatisfy { allowed.contains($0) }
        }
    }
}
public struct FormTextInput: View {
    public enum ValidationStatus: Equatable {
        case ok
        case failure(String)
        public var isSuccess: Bool { if case .ok = self { true } else { false } }
    }
    public enum InputType {
        case multiline, oneline
        case secureOneline(SecureInput.Configuration)
    }
    let title: LocalizedStringResource
    let placeholder: LocalizedStringResource?
    let footer: LocalizedStringResource?
    @Binding var text: String
    @Binding var validation: ValidationStatus
    let inputType: InputType
    @State private var isSecure = true
    public init(
        title: LocalizedStringResource, placeholder: LocalizedStringResource? = nil, footer: LocalizedStringResource? = nil, text: Binding<String>, validation: Binding<ValidationStatus>,
        inputType: InputType,
    ) {
        self.title = title
        self.placeholder = placeholder
        self.footer = footer
        _text = text
        _validation = validation
        self.inputType = inputType
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            Group {
                switch inputType {
                case .multiline: TextField(placeholder.map { String(localized: $0) } ?? "", text: $text, axis: .vertical).lineLimit(3...)
                case .oneline: TextField(placeholder.map { String(localized: $0) } ?? "", text: $text)
                case .secureOneline(let config):
                    HStack {
                        SecureInput(configuration: config, text: $text, isSecure: $isSecure).frame(minHeight: 24)
                        Button {
                            isSecure.toggle()
                        } label: {
                            Image(systemName: isSecure ? "eye" : "eye.slash")
                        }
                        .accessibilityLabel(isSecure ? "Show password" : "Hide password")
                    }
                }
            }
            .padding().background(Color(uiColor: .secondarySystemGroupedBackground)).roundedRectangleStyle()
            if case .failure(let message) = validation { Text(message).foregroundStyle(.red).font(.footnote) } else if let footer { Text(footer).foregroundStyle(.secondary).font(.footnote) }
        }
    }
}
extension Binding where Value == FormTextInput.ValidationStatus { public static var noValidation: Self { .constant(.ok) } }

public extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
