//
//  TelemetryMeasurements.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import UIKit

public class TelemetryMeasurement {
    let name: String

    init(name: String) {
        self.name = name
    }

    func flush() -> Any? {
        return nil
    }
}

public class StaticTelemetryMeasurement: TelemetryMeasurement {
    private let value: Any

    init(name: String, value: Any) {
        self.value = value
        super.init(name: name)
    }
    
    override func flush() -> Any? {
        return self.value
    }
}

public class ArchitectureMeasurement: StaticTelemetryMeasurement {
    init() {
        #if arch(i386)
            super.init(name: "arch", value: "i386")
        #elseif arch(x86_64)
            super.init(name: "arch", value: "x86_64")
        #elseif arch(arm)
            super.init(name: "arch", value: "arm")
        #elseif arch(arm64)
            super.init(name: "arch", value: "arm64")
        #else
            super.init(name: "arch", value: "unknown")
        #endif
    }
}

public class CreatedMeasurement: StaticTelemetryMeasurement {
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        super.init(name: "created", value: dateFormatter.string(from: Date()))
    }
}

public class DefaultSearchMeasurement: TelemetryMeasurement {
    private var searchEngine: String

    init() {
        self.searchEngine = "unknown"

        super.init(name: "defaultSearch")
    }
    
    override func flush() -> Any? {
        return searchEngine
    }
    
    public func change(searchEngine: String) {
        self.searchEngine = searchEngine
    }
}

public class DeviceMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "device", value: UIDevice.current.model)
    }
}

public class DistributionMeasurement: StaticTelemetryMeasurement {
    init(distributionId: String) {
        super.init(name: "distributionId", value: distributionId)
    }
}

public class EventsMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    private let storage: TelemetryStorage
    
    private var events: [TelemetryEvent]
    
    public var numberOfEvents: Int {
        get {
            return events.count
        }
    }
    
    init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.configuration = configuration
        self.storage = storage
        
        self.events = []
        
        super.init(name: "events")
    }
    
    public func add(event: TelemetryEvent) {
        events.append(event)

        // XXX: TODO - Persist to disk
    }
    
    override func flush() -> Any? {
        // XXX: TODO
        return nil
    }
}

public class ExperimentMeasurement: StaticTelemetryMeasurement {
    init(experiments: [String]) {
        super.init(name: "experiments", value: experiments)
    }
}

public class LocaleMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "locale", value: "\(NSLocale.current.languageCode!)-\(NSLocale.current.regionCode!)")
    }
}

public class OperatingSystemMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "os", value: UIDevice.current.systemName)
    }
}

public class OperatingSystemVersionMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "osversion", value: UIDevice.current.systemVersion)
    }
}

public class ProfileDateMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
    
        super.init(name: "profileDate")
    }

    override func flush() -> Any? {
        let oneSecondInMilliseconds: UInt64 = 1000
        let oneMinuteInMilliseconds: UInt64 = 60 * oneSecondInMilliseconds
        let oneHourInMilliseconds: UInt64 = 60 * oneMinuteInMilliseconds
        let oneDayInMilliseconds: UInt64 = 24 * oneHourInMilliseconds

        if let url = try? FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(configuration.profileFilename) {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                let seconds = UInt64(creationDate.timeIntervalSince1970)
                let days = UInt64(seconds * oneSecondInMilliseconds / oneDayInMilliseconds)
                
                return days
            }
        }

        // Fallback to current date if profile cannot be found
        let seconds = UInt64(Date().timeIntervalSince1970)
        let days = UInt64(seconds * oneSecondInMilliseconds / oneDayInMilliseconds)
        
        return days
    }
}

public class SearchesMeasurement: TelemetryMeasurement {
    init() {
        super.init(name: "searches")
    }
    
    override func flush() -> Any? {
        // XXX: TODO
        return nil
    }
    
    public func search(location: String, searchEngine: String) {
        // XXX: TODO
    }
}

public class SequenceMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    private let pingType: String
    
    init(storage: TelemetryStorage, pingType: String) {
        self.storage = storage
        self.pingType = pingType

        super.init(name: "seq")
    }
    
    override func flush() -> Any? {
        var sequence: UIntMax = storage.get(valueFor: "\(pingType)-seq") as? UIntMax ?? 0

        sequence += 1
        
        storage.set(key: "\(pingType)-seq", value: sequence)

        return sequence
    }
}

public class SessionCountMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        super.init(name: "sessions")
    }
    
    override func flush() -> Any? {
        let sessions: UIntMax = storage.get(valueFor: "sessions") as? UIntMax ?? 0
        
        // XXX: Reset sessions count?
        storage.set(key: "sessions", value: 0)
        
        return sessions
    }
    
    public func increment() {
        var sessions: UIntMax = storage.get(valueFor: "sessions") as? UIntMax ?? 0
        
        sessions += 1

        storage.set(key: "sessions", value: sessions)
    }
}

public class SessionDurationMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    private var startTime: Date?
    private var lastDuration: UInt64
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        self.startTime = nil
        self.lastDuration = 0
        
        super.init(name: "durations")
    }
    
    override func flush() -> Any? {
        let result = lastDuration

        lastDuration = 0
        // TODO: Clear stored duration
        
        return result
    }
    
    public func start() throws {
        if startTime != nil {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorSessionAlreadyStarted, userInfo: [NSLocalizedDescriptionKey: "Session is already started"])
        }
        
        startTime = Date()
    }
    
    public func end() throws {
        if startTime == nil {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorSessionNotStarted, userInfo: [NSLocalizedDescriptionKey: "Session has not started"])
        }

        lastDuration = UInt64(Date().timeIntervalSince(startTime!))
        // TODO: Store lastDuration

        startTime = nil
    }
}

public class SettingsMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration

        super.init(name: "settings")
    }
    
    override func flush() -> Any? {
        // XXX: TODO
        return nil
    }
}

public class TimezoneOffsetMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "tz", value: TimeZone.current.abbreviation() ?? "")
    }
}

public class VersionMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "v", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
    }
}
