// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

enum ProtonAPIErrorCode {
    static func parse(_ payload: String) -> Int? {
        struct Response: Decodable {
            let Code: UInt32
        }
        if let response = try? JSONDecoder().decode(Response.self, from: Data(payload.utf8)) {
            return Int(response.Code)
        }

        // SDK 0.165.4 carries ApiErrorInfo's Rust Debug or Display output.
        let patterns = [
            #"^Some\(ApiErrorInfo \{ code: ([0-9]+), error: (?:None|Some\("(?:[^"\\]|\\.)*"\)), details: (?:None|Some\(.*\)) \}\)$"#,
            #"^([0-9]+): (?:None|Some\("(?:[^"\\]|\\.)*"\)) \((?:None|Some\(.*\))\)$"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: payload, range: NSRange(payload.startIndex..., in: payload)),
                  let range = Range(match.range(at: 1), in: payload),
                  let code = UInt32(payload[range]) else { continue }
            return Int(code)
        }
        return nil
    }
}
