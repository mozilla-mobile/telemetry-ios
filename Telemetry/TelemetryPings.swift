//
//  TelemetryPing.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

class TelemetryPing {
    private let documentId: String
    private let type: String
    private let storage: TelemetryStorage
    
    private var measurements: Dictionary<String, TelemetryMeasurement>
    
    init(type: String, storage: TelemetryStorage, measurements: [TelemetryMeasurement]) {
        self.documentId = UUID.init().uuidString
        self.type = type
        self.storage = storage

        self.measurements = [:]

        for measurement in measurements {
            addMeasurement(measurement: measurement)
        }
    }
    
    func addMeasurement(measurement: TelemetryMeasurement) {
        self.measurements[measurement.name] = measurement
    }
    
    func flushMeasurements() -> Dictionary<String, Any> {
        var results: Dictionary<String, Any> = [:]
        
        for (name, measurement) in self.measurements {
            results[name] = measurement.flush()
        }
        
        return results
    }
}

class TelemetryCorePing: TelemetryPing {
    private let sessionDurationMeasurement: SessionDurationMeasurement

    init(storage: TelemetryStorage) {
        self.sessionDurationMeasurement = SessionDurationMeasurement()
        
        super.init(type: "core", storage: storage, measurements: [
            SequenceMeasurement(pingType: "core"),
            LocaleMeasurement(),
            OperatingSystemMeasurement(),
            OperatingSystemVersionMeasurement(),
            DeviceMeasurement(),
            ArchitectureMeasurement(),
            // ProfileDateMeasurement(profileDate: <#T##UIntMax#>),
            // DefaultSearchMeasurement(defaultSearch: <#T##String#>),
            // DistributionMeasurement(distributionId: <#T##String#>),
            CreatedMeasurement(),
            TimezoneOffsetMeasurement(),
            SessionCountMeasurement(),
            self.sessionDurationMeasurement,
            // SearchMeasurement(searches: <#T##Dictionary<String, UIntMax>#>),
            // ExperimentMeasurement(experiments: <#T##[String]#>)
        ])
    }
    
    func startSession() {
        self.sessionDurationMeasurement.recordSessionStart()
    }
    
    func endSession() {
        self.sessionDurationMeasurement.recordSessionEnd()
    }
}
