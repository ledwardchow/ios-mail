// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import proton_app_uniffi

extension ProtonError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .otherReason(let reason):
            switch reason {
            case .invalidParameter:
                return String(localized: "An invalid parameter was provided.")
            case .taskCancelled:
                return String(localized: "The task was cancelled.")
            case .other(let message):
                return message
            }
        case .serverError(let error):
            switch error {
            case .badRequest(let message), .unauthorized(let message), .forbidden(let message),
                 .notFound(let message), .unprocessableEntity(let message), .tooManyRequests(let message),
                 .internalServerError(let message), .notImplemented(let message), .badGateway(let message),
                 .serviceUnavailable(let message), .otherHttpError(_, let message),
                 .networkFailure(let message), .internal(let message):
                return message
            }
        case .network:
            return String(localized: "A network error occurred.")
        case .unexpected(let category):
            return String(localized: "An unexpected error occurred (\(String(describing: category))).")
        case .nonProcessableActions:
            return String(localized: "The requested actions could not be processed.")
        }
    }
}
