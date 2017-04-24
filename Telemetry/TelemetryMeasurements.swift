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
    
    private var events: [TelemetryEvent]
    
    public var numberOfEvents: Int {
        get {
            return events.count
        }
    }
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
        
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
    init() {
        super.init(name: "profileDate")
    }
    
    override func flush() -> Any? {
        // XXX: TODO
        return nil
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
    private let configuration: TelemetryConfiguration
    private let pingType: String

    private var sequence: UIntMax
    
    init(configuration: TelemetryConfiguration, pingType: String) {
        self.configuration = configuration
        self.pingType = pingType

        // TODO: Read last sequence from storage
        self.sequence = 0

        super.init(name: "seq")
    }
    
    override func flush() -> Any? {
        // TODO: Save new sequence to storage
        self.sequence += 1

        return self.sequence
    }
}

public class SessionCountMeasurement: TelemetryMeasurement {
    private var count: UIntMax
    
    init() {
        self.count = 0
        
        super.init(name: "sessions")
    }
    
    override func flush() -> Any? {
        let result = count
        
        count = 0
        // TODO: Clear stored count
        
        return result
    }
    
    public func increment() {
        count += 1
        // TODO: Store count
    }
}

public class SessionDurationMeasurement: TelemetryMeasurement {
    private var startTime: Date?
    private var lastDuration: UInt64
    
    init() {
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
