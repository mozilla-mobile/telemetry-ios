/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class TelemetryError {
    public static let ErrorDomain: String = "TelemetryErrorDomain"

    public static let SessionAlreadyStarted: Int = 101
    public static let SessionNotStarted: Int = 102
    public static let InvalidUploadURL: Int = 103
    public static let CannotGenerateJSON: Int = 104
    public static let UnknownUploadError: Int = 105
}
