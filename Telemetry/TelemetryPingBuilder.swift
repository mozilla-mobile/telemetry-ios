//
//  TelemetryPingBuilder.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 4/18/17.
//
//

import Foundation

public class TelemetryPingBuilder {
    public class var PingType: String {
        return "unknown"
    }
    
    public class var Version: Int {
        return -1
    }

    public let documentId: String
    
    private(set) public var measurements: [TelemetryMeasurement]

    fileprivate let configuration: TelemetryConfiguration
    fileprivate let storage: TelemetryStorage

    public var canBuild: Bool {
        get { return true }
    }
    
    public var uploadPath: String {
        get {
            let pingType = type(of: self).PingType
            let appName = configuration.appName
            let appVersion = configuration.appVersion
            let updateChannel = configuration.updateChannel
            let buildId = configuration.buildId
            return "/submit/telemetry/\(documentId)/\(pingType)/\(appName)/\(appVersion)/\(updateChannel)/\(buildId)"
        }
    }
    
    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.documentId = UUID.init().uuidString
        
        self.measurements = []
        
        self.configuration = configuration
        self.storage = storage
    }
    
    public func add(measurement: TelemetryMeasurement) {
        measurements.append(measurement)
    }
    
    public func build() -> TelemetryPing {
        let pingType = type(of: self).PingType
        return TelemetryPing(pingType: pingType, documentId: documentId, uploadPath: uploadPath, measurements: flushMeasurements(), timestamp: Date().timeIntervalSince1970)
    }
    
    private func flushMeasurements() -> [String : Any?] {
        var results: [String : Any?] = [:]
        
        for measurement in measurements {
            if let value = measurement.flush() {
                results[measurement.name] = value
            }
        }
        
        return results
    }
}

public class CorePingBuilder: TelemetryPingBuilder {
    override public class var PingType: String {
        return "core"
    }
    
    override public class var Version: Int {
        return 7
    }
    
    private let sessionCountMeasurement: SessionCountMeasurement
    private let sessionDurationMeasurement: SessionDurationMeasurement
    private let defaultSearchMeasurement: DefaultSearchMeasurement
    private let searchesMeasurement: SearchesMeasurement

    override public var uploadPath: String {
        get {
            return super.uploadPath + "?v=4"
        }
    }
    
    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.sessionCountMeasurement = SessionCountMeasurement(storage: storage)
        self.sessionDurationMeasurement = SessionDurationMeasurement(storage: storage)
        self.defaultSearchMeasurement = DefaultSearchMeasurement()
        self.searchesMeasurement = SearchesMeasurement()
        
        super.init(configuration: configuration, storage: storage)
        
        self.add(measurement: ClientIdMeasurement(storage: storage))
        self.add(measurement: SequenceMeasurement(storage: storage, pingType: type(of: self).PingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: DeviceMeasurement())
        self.add(measurement: ArchitectureMeasurement())
        self.add(measurement: ProfileDateMeasurement(configuration: configuration))
        self.add(measurement: CreatedDateMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
        self.add(measurement: VersionMeasurement(version: type(of: self).Version))
        self.add(measurement: self.sessionCountMeasurement)
        self.add(measurement: self.sessionDurationMeasurement)
        self.add(measurement: self.defaultSearchMeasurement)
        self.add(measurement: self.searchesMeasurement)
    }
    
    public func startSession() throws {
        try sessionDurationMeasurement.start()
        sessionCountMeasurement.increment()
    }
    
    public func endSession() throws {
        try sessionDurationMeasurement.end()
    }
    
    public func changeDefaultSearch(searchEngine: String) {
        defaultSearchMeasurement.change(searchEngine: searchEngine)
    }
    
    public func search(location: String, searchEngine: String) {
        searchesMeasurement.search(location: location, searchEngine: searchEngine)
    }
}

public class FocusEventPingBuilder: TelemetryPingBuilder {
    override public class var PingType: String {
        return "focus-event"
    }
    
    override public class var Version: Int {
        return 1
    }
    
    private let eventsMeasurement: EventsMeasurement
    
    public var numberOfEvents: Int {
        get {
            return eventsMeasurement.numberOfEvents
        }
    }
    
    override public var canBuild: Bool {
        get {
            return eventsMeasurement.numberOfEvents >= configuration.minimumEventsForUpload
        }
    }
    
    override public var uploadPath: String {
        get {
            return super.uploadPath + "?v=4"
        }
    }
    
    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.eventsMeasurement = EventsMeasurement(storage: storage, pingType: type(of: self).PingType)
        
        super.init(configuration: configuration, storage: storage)

        self.add(measurement: ClientIdMeasurement(storage: storage))
        self.add(measurement: SequenceMeasurement(storage: storage, pingType: type(of: self).PingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: CreatedTimestampMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
        self.add(measurement: UserDefaultsMeasurement(configuration: configuration))
        self.add(measurement: VersionMeasurement(version: type(of: self).Version))
        
        self.add(measurement: self.eventsMeasurement)
    }
    
    public func add(event: TelemetryEvent) {
        self.eventsMeasurement.add(event: event)
    }
}
