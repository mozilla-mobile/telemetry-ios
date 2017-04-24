//
//  TelemetryDefaults.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 4/18/17.
//
//

import Foundation

public struct TelemetryDefaults {
    public static let AppName = "unknown"
    public static let AppVersion = "unknown"
    public static let BuildId = "unknown"
    public static let UpdateChannel = "unknown"
    public static let ServerEndpoint = "https://incoming.telemetry.mozilla.org"
    public static let UserAgent = "Telemetry/1.0 (iOS)"
    public static let DataDirectory = FileManager.SearchPathDirectory.cachesDirectory
    public static let InitialBackoffForUpload = 30000
    public static let ConnectTimeout = 10000
    public static let ReadTimeout = 30000
    public static let MinNumberOfEventsPerUpload = 3
    public static let MaxNumberOfEventsPerPing = 500
    public static let MaxNumberOfPingsPerType = 40
    public static let MaxNumberOfPingUploadsPerDay = 100
}
