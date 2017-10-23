/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

#if !DEBUG
    // Turn print into a no-op in non-debug builds.
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

extension UInt64 {
    static func safeConvert<T: FloatingPoint>(_ val: T) -> UInt64 {
        let d = val as? Double ?? 0.0
        return UInt64(Swift.max(0.0, d))
    }

    static func safeConvert<T: Integer>(_ val: T) -> UInt64 {
        return UInt64(Swift.max(0, val))
    }
}

class TelemetryUtils {
    static func asString(_ object: Any?) -> String {
        if let string = object as? String {
            return string
        } else if let bool = object as? Bool {
            return bool ? "true" : "false"
        } else {
            return object.debugDescription
        }
    }
    
    static func truncate(string: String?, maxLength: Int) -> String? {
        guard let string = string else {
            return nil
        }
        
        return String(string.characters.prefix(maxLength))
    }

    static func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
