//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class Telemetry {
    public static let ErrorDomain: String = "TelemetryErrorDomain"
    
    public static let ErrorWrongConfiguration: Int = 101
    public static let ErrorTooManyEventExtras: Int = 102
    public static let ErrorSessionAlreadyStarted: Int = 103
    public static let ErrorSessionNotStarted: Int = 104

    public let configuration: TelemetryConfiguration
    
    private let storage: TelemetryStorage
    private let client: TelemetryClient
    private let scheduler: TelemetryScheduler

    private var pingBuilders: [String : TelemetryPingBuilder]
    
    public static let `default`: Telemetry = {
        return Telemetry(storageName: "MozTelemetry")
    }()
    
    public init(storageName: String) {
        self.configuration = TelemetryConfiguration()
        
        self.storage = TelemetryStorage(name: storageName, configuration: configuration)
        self.client = TelemetryClient()
        self.scheduler = TelemetryScheduler()
        
        self.pingBuilders = [:]
    }
    
    public func add<T: TelemetryPingBuilder>(pingBuilderType: T.Type) -> Telemetry {
        let pingBuilder = pingBuilderType.init(configuration: configuration, storage: storage)
        pingBuilders[pingBuilderType.PingType] = pingBuilder
        return self
    }
    
    public func queue(pingType: String) throws -> Telemetry {
        if !self.configuration.isCollectionEnabled {
            return self
        }
        
        guard let pingBuilder = self.pingBuilders[pingType] else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(pingType)"])
        }
        
        DispatchQueue.main.async {
            let ping = pingBuilder.build()
            self.storage.store(ping: ping)
        }
        return self
    }
    
    public func queueEvent(event: TelemetryEvent) throws -> Telemetry {
        if !self.configuration.isCollectionEnabled {
            return self
        }
        
        guard let pingBuilder: FocusEventPingBuilder = self.pingBuilders[FocusEventPingBuilder.PingType] as? FocusEventPingBuilder else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(FocusEventPingBuilder.PingType)"])
        }

        DispatchQueue.main.async {
            pingBuilder.add(event: event)

            if pingBuilder.numberOfEvents < self.configuration.maximumNumberOfEventsPerPing {
                return
            }

            let ping = pingBuilder.build()
            self.storage.store(ping: ping)
        }
        return self
    }
    
    public func scheduleUpload() -> Telemetry {
        DispatchQueue.main.async {
            if !self.configuration.isUploadEnabled {
                return
            }
            
            self.scheduler.scheduleUpload(configuration: self.configuration)
        }
        return self
    }
    
    public func recordSessionStart() throws -> Telemetry {
        if !configuration.isCollectionEnabled {
            return self
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        try pingBuilder.startSession()
        return self
    }
    
    public func recordSessionEnd() throws -> Telemetry {
        if !configuration.isCollectionEnabled {
            return self
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        try pingBuilder.endSession()
        return self
    }
    
    public func recordDefaultSearchProviderChange(searchEngine: String) throws -> Telemetry {
        if !configuration.isCollectionEnabled {
            return self
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        pingBuilder.changeDefaultSearch(searchEngine: searchEngine)
        
        return self
    }
    
    public func recordSearch(location: String, searchEngine: String) throws -> Telemetry {
        if !configuration.isCollectionEnabled {
            return self
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorWrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        pingBuilder.search(location: location, searchEngine: searchEngine)
        
        return self
    }
    
//    private func upload(completionHandler: @escaping (Data?, Error?)->Void = {_,_ in }) {
//        client.send(request: URLRequest(url: URL(string: "https://incoming.telemetry.mozilla.org")!)) { (response, data, error) in
//            if error != nil {
//                completionHandler(nil, error)
//                return
//            }
//
//            completionHandler(data, nil)
//        }
//    }
}
