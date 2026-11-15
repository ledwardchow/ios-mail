# Public build UI compatibility

Controls.swift and Toast.swift are new GPL-3.0-or-later implementations written for this fork against the calling interfaces in the public Proton Mail iOS source. They use Apple's SwiftUI/UIKit/Combine frameworks. They are not copies of Proton's unavailable ProtonUIFoundations package, do not claim identical layout, and contain no authentication, cryptography, payment processing, or private endpoints.

The public ProtonMail/protoncore_ios repository at bb1279db594cb5aeeffcddadad23b8dd8a02104a was inspected. Its older ProtonCoreUIFoundations API does not provide the current app's APIs; no source or assets were copied from it.

The neighboring ProtonCoreUtilities/Observation.swift is also a new GPL-3.0-or-later implementation. It forwards nested ObservableObject changes and reads Apple's standard SwiftUI preview environment variable.

Verification: both modules independently pass swiftc type checking against the iOS Simulator SDK, targeting arm64 iOS 17. Full application integration and runtime UI checks are separate. Existing private-package snapshot fixtures (ToastViewPreviewProvider) are not recreated here; original visual snapshot parity is not expected.
