// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import proton_app_uniffi

public extension UserApiServiceError {
    var errorCode: Int? {
        let payload: String
        switch self {
        case .badRequest(let message), .unauthorized(let message), .forbidden(let message),
             .notFound(let message), .unprocessableEntity(let message), .tooManyRequests(let message),
             .internalServerError(let message), .notImplemented(let message), .badGateway(let message),
             .serviceUnavailable(let message), .otherHttpError(_, let message):
            payload = message
        case .networkFailure, .internal:
            return nil
        }
        return ProtonAPIErrorCode.parse(payload)
    }
}
