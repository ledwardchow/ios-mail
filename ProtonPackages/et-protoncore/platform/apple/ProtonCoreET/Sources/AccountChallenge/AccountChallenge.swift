// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import proton_app_uniffi

public final class AccountChallengeCoordinator: ChallengeNotifier, Sendable {
    public init(apiConfig: ApiConfig, appDetails: AppDetails) {}
    public func onChallenge(server: ChallengeServer, payload: ChallengePayload) async -> ChallengeResponse {
        // Never manufacture verification tokens or bypass a server challenge.
        await MainActor.run {
            NotificationCenter.default.post(name: Self.unsupportedChallenge, object: nil)
        }
        return .cancelled
    }
    public static let unsupportedChallenge = Notification.Name("ProtonDuo.unsupportedHumanVerification")
}

public final class ChallengePayloadProvider: DeviceInfoProvider, Sendable {
    public init() {}
    @MainActor public func getDeviceInfo() async -> DeviceInfo {
        let device = UIDevice.current
        let storage = (try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemSize] as? NSNumber)?.doubleValue ?? 0
        return DeviceInfo(
            language: Locale.current.language.languageCode?.identifier ?? "en",
            timezone: TimeZone.current.identifier,
            timezoneOffset: Int32(TimeZone.current.secondsFromGMT() / 60),
            model: device.model, brand: "Apple", codename: device.model,
            uuid: device.identifierForVendor?.uuidString ?? "",
            country: Locale.current.region?.identifier ?? "", rooted: false,
            fontScale: String(UIFont.preferredFont(forTextStyle: .body).pointSize / 17),
            storage: storage / 1_000_000_000,
            darkMode: UITraitCollection.current.userInterfaceStyle == .dark,
            keyboards: UITextInputMode.activeInputModes.compactMap(\.primaryLanguage),
        )
    }
}
