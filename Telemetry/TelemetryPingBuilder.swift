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
    
    public let configuration: TelemetryConfiguration

    public let documentId: String
    
    private var measurements: [TelemetryMeasurement]
    
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
    
    required public init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
        
        self.documentId = UUID.init().uuidString
        
        self.measurements = []
    }
    
    public func add(measurement: TelemetryMeasurement) {
        measurements.append(measurement)
    }
    
    public func build() -> TelemetryPing {
        let pingType = type(of: self).PingType
        return TelemetryPing(pingType: pingType, documentId: documentId, uploadPath: uploadPath, measurements: flushMeasurements())
    }
    
    private func flushMeasurements() -> Dictionary<String, Any?> {
        var results: Dictionary<String, Any?> = [:]
        
        for measurement in measurements {
            results[measurement.name] = measurement.flush()
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
    
    required public init(configuration: TelemetryConfiguration) {
        self.sessionCountMeasurement = SessionCountMeasurement()
        self.sessionDurationMeasurement = SessionDurationMeasurement()
        self.defaultSearchMeasurement = DefaultSearchMeasurement()
        self.searchesMeasurement = SearchesMeasurement()
        
        super.init(configuration: configuration)
        
        let pingType = type(of: self).PingType
        
        self.add(measurement: SequenceMeasurement(configuration: self.configuration, pingType: pingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: DeviceMeasurement())
        self.add(measurement: ArchitectureMeasurement())
        self.add(measurement: ProfileDateMeasurement())
        self.add(measurement: CreatedMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
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
    
    required public init(configuration: TelemetryConfiguration) {
        self.eventsMeasurement = EventsMeasurement(configuration: configuration)
        
        super.init(configuration: configuration)
        
        let pingType = type(of: self).PingType

        self.add(measurement: SequenceMeasurement(configuration: self.configuration, pingType: pingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: CreatedMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
        self.add(measurement: SettingsMeasurement(configuration: configuration))
        
        self.add(measurement: self.eventsMeasurement)
    }
    
    public func add(event: TelemetryEvent) {
        self.eventsMeasurement.add(event: event)
    }
}
