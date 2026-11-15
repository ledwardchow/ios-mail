// SPDX-License-Identifier: GPL-3.0-or-later
// Public-build compatibility implementations using Foundation and SwiftUI.
import SwiftUI
import UIKit

extension LocalizedStringResource {
    public var string: String { String(localized: self) }
}

extension Color {
    /// Accepts RGB, RRGGBB, and RRGGBBAA in the sRGB color space.
    public init(hex: String) {
        let text = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard let value = UInt64(text, radix: 16) else {
            self = .clear
            return
        }
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
        switch text.count {
        case 3:
            red = Double((value >> 8) & 15) / 15
            green = Double((value >> 4) & 15) / 15
            blue = Double(value & 15) / 15
            alpha = 1
        case 6:
            red = Double((value >> 16) & 255) / 255
            green = Double((value >> 8) & 255) / 255
            blue = Double(value & 255) / 255
            alpha = 1
        case 8:
            red = Double((value >> 24) & 255) / 255
            green = Double((value >> 16) & 255) / 255
            blue = Double((value >> 8) & 255) / 255
            alpha = Double(value & 255) / 255
        default:
            self = .clear
            return
        }
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    public func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "#000000" }
        func component(_ value: CGFloat) -> Int { Int((min(1, max(0, value)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", component(red), component(green), component(blue))
    }
}

public extension EdgeInsets {
    init(vertical: CGFloat, horizontal: CGFloat) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}

public extension String {
    static var empty: String { "" }
}
