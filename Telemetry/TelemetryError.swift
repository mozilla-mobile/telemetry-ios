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
    
    public static let WrongConfiguration: Int = 101
    public static let TooManyEventExtras: Int = 102
    public static let SessionAlreadyStarted: Int = 103
    public static let SessionNotStarted: Int = 104
    public static let InvalidUploadURL: Int = 105
    public static let CannotGenerateJSON: Int = 106
}
