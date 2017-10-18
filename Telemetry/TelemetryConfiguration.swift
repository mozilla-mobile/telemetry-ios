//
//  TelemetryConfiguration.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 4/18/17.
//
//

import Foundation

public class TelemetryConfiguration {
    public var appName: String
    public var appVersion: String
    public var buildId: String
    
    public var updateChannel = TelemetryDefaults.UpdateChannel
    public var serverEndpoint = TelemetryDefaults.ServerEndpoint
    public var userAgent = TelemetryDefaults.UserAgent
    public var defaultSearchEngineProvider = TelemetryDefaults.DefaultSearchEngineProvider
    public var sessionConfigurationBackgroundIdentifier = TelemetryDefaults.SessionConfigurationBackgroundIdentifier
    public var dataDirectory = TelemetryDefaults.DataDirectory
    public var profileFilename = TelemetryDefaults.ProfileFilename
    public var minimumEventsForUpload = TelemetryDefaults.MinNumberOfEventsPerUpload
    public var maximumNumberOfEventsPerPing = TelemetryDefaults.MaxNumberOfEventsPerPing
    public var maximumNumberOfPingsPerType = TelemetryDefaults.MaxNumberOfPingsPerType
    public var maximumNumberOfPingUploadsPerDay = TelemetryDefaults.MaxNumberOfPingUploadsPerDay
    public var maximumAgeOfPingInDays = TelemetryDefaults.MaxAgeOfPingInDays

    public var isCollectionEnabled = true
    public var isUploadEnabled = true

    public var userDefaultsSuiteName: String?
    private(set) public var measuredUserDefaults: [[String : Any?]]
    
    public init() {
        let info = Bundle.main.infoDictionary

        self.appName = info?["CFBundleDisplayName"] as? String ?? TelemetryDefaults.AppName
        self.appVersion = info?["CFBundleShortVersionString"] as? String ?? TelemetryDefaults.AppVersion
        self.buildId = info?["CFBundleVersion"] as? String ?? TelemetryDefaults.BuildId
        
        self.userDefaultsSuiteName = nil
        self.measuredUserDefaults = []
    }
    
    public func measureUserDefaultsSetting(forKey key: String, withDefaultValue defaultValue: Any?) {
        measuredUserDefaults.append(["key": key, "defaultValue": defaultValue])
    }
    
    public func measureUserDefaultsSetting<T : RawRepresentable>(forKey key: T, withDefaultValue defaultValue: Any?) where T.RawValue == String {
        measureUserDefaultsSetting(forKey: key.rawValue, withDefaultValue: defaultValue)
    }
}
