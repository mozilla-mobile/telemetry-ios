//
//  TelemetryError.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 5/3/17.
//
//

import Foundation

public class TelemetryError {
    public static let ErrorDomain: String = "TelemetryErrorDomain"

    public static let SessionAlreadyStarted: Int = 101
    public static let SessionNotStarted: Int = 102
    public static let InvalidUploadURL: Int = 103
    public static let CannotGenerateJSON: Int = 104
    public static let UnknownUploadError: Int = 105
    public static let CannotGeneratePing: Int = 106
}
