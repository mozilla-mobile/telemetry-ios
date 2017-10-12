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

public class ClientIdMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    private var value: String?
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        super.init(name: "clientId")
    }
    
    override func flush() -> Any? {
        if value != nil {
            return value
        }
        
        if let clientId = storage.get(valueFor: "clientId") as? String {
            value = clientId
            return value
        }
        
        value = UUID.init().uuidString
        
        storage.set(key: "clientId", value: value)
        
        return value
    }
}

public class CreatedDateMeasurement: StaticTelemetryMeasurement {
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        super.init(name: "created", value: dateFormatter.string(from: Date()))
    }
}

public class CreatedTimestampMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "created", value: UInt64(Date().timeIntervalSince1970 * 1000))
    }
}

public class DefaultSearchMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration

        super.init(name: "defaultSearch")
    }
    
    override func flush() -> Any? {
        return self.configuration.defaultSearchEngineProvider
    }
}

public class DeviceMeasurement: StaticTelemetryMeasurement {
    static let modelInfo: String = {
        var sysinfo = utsname()
        uname(&sysinfo)
        let rawModel = NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)!
        return rawModel.trimmingCharacters(in: NSCharacterSet.controlCharacters)
    }()

    init() {
        super.init(name: "device", value: DeviceMeasurement.modelInfo)
    }
}

public class DistributionMeasurement: StaticTelemetryMeasurement {
    init(distributionId: String) {
        super.init(name: "distributionId", value: distributionId)
    }
}

public class EventsMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    private let pingType: String
    
    private var events: [[Any?]]
    
    public var numberOfEvents: Int {
        get {
            return events.count
        }
    }
    
    init(storage: TelemetryStorage, pingType: String) {
        self.storage = storage
        self.pingType = pingType
        
        self.events = storage.get(valueFor: "\(pingType)-events") as? [[Any?]] ?? []
        
        super.init(name: "events")
    }
    
    public func add(event: TelemetryEvent) {
        events.append(event.toArray())

        storage.set(key: "\(pingType)-events", value: events)
    }
    
    override func flush() -> Any? {
        let events = self.events
        
        self.events = []
        storage.set(key: "\(pingType)-events", value: self.events)
        
        return events
    }
}

public class ExperimentMeasurement: StaticTelemetryMeasurement {
    init(experiments: [String]) {
        super.init(name: "experiments", value: experiments)
    }
}

public class LocaleMeasurement: StaticTelemetryMeasurement {
    init() {
        if NSLocale.current.languageCode == nil {
            super.init(name: "locale", value: "??")
        } else {
            if NSLocale.current.regionCode == nil {
                super.init(name: "locale", value: NSLocale.current.languageCode!)
            } else {
                super.init(name: "locale", value: "\(NSLocale.current.languageCode!)-\(NSLocale.current.regionCode!)")
            }
        }
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
    public enum SearchLocation: String {
        case actionBar = "actionbar"
        case listItem = "listitem"
        case suggestion = "suggestion"
        case quickSearch = "quicksearch"
    }
    
    private let storage: TelemetryStorage
    
    init(storage: TelemetryStorage) {
        self.storage = storage

        super.init(name: "searches")
    }
    
    override func flush() -> Any? {
        let searches = storage.get(valueFor: "searches")

        storage.set(key: "searches", value: [:])
        
        return searches
    }
    
    public func search(location: SearchLocation, searchEngine: String) {
        var searches = storage.get(valueFor: "searches") as? [String : UInt] ?? [:]
        let key = "\(location.rawValue).\(searchEngine)"
        var count = searches[key] ?? 0
        
        count += 1

        searches[key] = count
        
        storage.set(key: "searches", value: searches)
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
        var sequence: UInt64 = storage.get(valueFor: "\(pingType)-seq") as? UInt64 ?? 0

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
        let sessions: UInt64 = storage.get(valueFor: "sessions") as? UInt64 ?? 0
        
        storage.set(key: "sessions", value: 0)
        
        return sessions
    }
    
    public func increment() {
        var sessions: UInt64 = storage.get(valueFor: "sessions") as? UInt64 ?? 0
        
        sessions += 1

        storage.set(key: "sessions", value: sessions)
    }
}

public class SessionDurationMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    private var startTime: Date?
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        self.startTime = nil
        
        super.init(name: "durations")
    }
    
    override func flush() -> Any? {
        let durations = storage.get(valueFor: "durations") as? UInt64 ?? 0
        
        storage.set(key: "durations", value: 0)
        
        // Reset the clock if we're in the middle of a session
        if startTime != nil {
            startTime = Date()
        }
        
        return durations
    }
    
    public func start() throws {
        if startTime != nil {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.SessionAlreadyStarted, userInfo: [NSLocalizedDescriptionKey: "Session is already started"])
        }
        
        startTime = Date()
    }
    
    public func end() throws {
        if startTime == nil {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.SessionNotStarted, userInfo: [NSLocalizedDescriptionKey: "Session has not started"])
        }
        
        var totalDurations = storage.get(valueFor: "durations") as? UInt64 ?? 0
        
        let duration = UInt64(Date().timeIntervalSince(startTime!))
        totalDurations += duration
        
        storage.set(key: "durations", value: totalDurations)

        startTime = nil
    }
}

public class TimezoneOffsetMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "tz", value: TimeZone.current.secondsFromGMT() / 60)
    }
}

public class UserDefaultsMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
        
        super.init(name: "settings")
    }
    
    override func flush() -> Any? {
        var settings: [String : Any?] = [:]
        
        let userDefaults = configuration.userDefaultsSuiteName != nil ? UserDefaults(suiteName: configuration.userDefaultsSuiteName) : UserDefaults()
        
        for var measuredUserDefault in configuration.measuredUserDefaults {
            if let key = measuredUserDefault["key"] as? String {
                if let value = userDefaults?.object(forKey: key) {
                    settings[key] = TelemetryUtils.asString(value)
                } else {
                    settings[key] = TelemetryUtils.asString(measuredUserDefault["defaultValue"] ?? nil)
                }
            }
        }

        return settings
    }
}

public class VersionMeasurement: StaticTelemetryMeasurement {
    init(version: Int) {
        super.init(name: "v", value: version)
    }
}
