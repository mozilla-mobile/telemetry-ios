//
//  TelemetryMeasurements.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import UIKit

class TelemetryMeasurement {
    let name: String

    init(name: String) {
        self.name = name
    }

    func flush() -> Any? {
        return nil
    }
}

class StaticTelemetryMeasurement: TelemetryMeasurement {
    private let value: Any

    init(name: String, value: Any) {
        self.value = value
        super.init(name: name)
    }
    
    override func flush() -> Any? {
        return self.value
    }
}

class ArchitectureMeasurement: StaticTelemetryMeasurement {
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

class CreatedMeasurement: StaticTelemetryMeasurement {
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        super.init(name: "created", value: dateFormatter.string(from: Date()))
    }
}

class DefaultSearchMeasurement: StaticTelemetryMeasurement {
    init(defaultSearch: String) {
        super.init(name: "defaultSearch", value: defaultSearch)
    }
}

class DeviceMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "device", value: UIDevice.current.model)
    }
}

class DistributionMeasurement: StaticTelemetryMeasurement {
    init(distributionId: String) {
        super.init(name: "distributionId", value: distributionId)
    }
}

class ExperimentMeasurement: StaticTelemetryMeasurement {
    init(experiments: [String]) {
        super.init(name: "experiments", value: experiments)
    }
}

class LocaleMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "locale", value: "\(NSLocale.current.languageCode!)-\(NSLocale.current.regionCode!)")
    }
}

class OperatingSystemMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "os", value: UIDevice.current.systemName)
    }
}

class OperatingSystemVersionMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "osversion", value: UIDevice.current.systemVersion)
    }
}

class ProfileDateMeasurement: StaticTelemetryMeasurement {
    init(profileDate: UIntMax) {
        super.init(name: "profileDate", value: profileDate)
    }
}

class SearchMeasurement: StaticTelemetryMeasurement {
    init(searches: Dictionary<String, UIntMax>) {
        super.init(name: "searches", value: searches)
    }
}

class SequenceMeasurement: TelemetryMeasurement {
    private var sequence: UIntMax

    init(pingType: String) {
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

class SessionCountMeasurement: TelemetryMeasurement {
    private var count: UIntMax
    
    init() {
        // TODO: Read last count from storage
        self.count = 0
        
        super.init(name: "sessions")
    }
    
    override func flush() -> Any? {
        // TODO: Save new count to storage
        self.count += 1
        
        return self.count
    }
}

class SessionDurationMeasurement: TelemetryMeasurement {
    private var startTime: UIntMax
    private var duration: UIntMax
    
    init() {
        // TODO: Read last startTime from storage
        self.startTime = 0
        self.duration = 0
        
        super.init(name: "sessions")
    }
    
    override func flush() -> Any? {
        // TODO: Save new count to storage
        self.duration += 1
        
        return self.duration
    }
    
    func recordSessionStart() {
        
    }
    
    func recordSessionEnd() {
        
    }
}

class TimezoneOffsetMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "tz", value: TimeZone.current.abbreviation() ?? "")
    }
}

class VersionMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "v", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
    }
}
