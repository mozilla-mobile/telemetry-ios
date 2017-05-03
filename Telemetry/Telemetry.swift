//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation
import UIKit

public class Telemetry {
    public let configuration: TelemetryConfiguration
    
    private let storage: TelemetryStorage
    private let scheduler: TelemetryScheduler

    private var pingBuilders: [String : TelemetryPingBuilder]
    
    public static let `default`: Telemetry = {
        return Telemetry(storageName: "MozTelemetry")
    }()
    
    public init(storageName: String) {
        self.configuration = TelemetryConfiguration()
        
        self.storage = TelemetryStorage(name: storageName, configuration: configuration)
        self.scheduler = TelemetryScheduler(configuration: configuration, storage: storage)
        
        self.pingBuilders = [:]
    }
    
    public func add<T: TelemetryPingBuilder>(pingBuilderType: T.Type) {
        let pingBuilder = pingBuilderType.init(configuration: configuration, storage: storage)
        pingBuilders[pingBuilderType.PingType] = pingBuilder
    }
    
    public func queue(pingType: String) throws {
        if !self.configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder = self.pingBuilders[pingType] else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(pingType)"])
        }
        
        DispatchQueue.main.async {
            let ping = pingBuilder.build()
            self.storage.enqueue(ping: ping)
        }
    }
    
    public func queueEvent(event: TelemetryEvent) throws {
        if !self.configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: FocusEventPingBuilder = self.pingBuilders[FocusEventPingBuilder.PingType] as? FocusEventPingBuilder else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(FocusEventPingBuilder.PingType)"])
        }

        DispatchQueue.main.async {
            pingBuilder.add(event: event)

            if pingBuilder.numberOfEvents < self.configuration.maximumNumberOfEventsPerPing {
                return
            }

            let ping = pingBuilder.build()
            self.storage.enqueue(ping: ping)
        }
    }
    
    public func scheduleUpload(pingType: String) {
        if !self.configuration.isUploadEnabled {
            return
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "MozTelemetryUpload") {
            // XXX: Clean up unfinished tasks?
            
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }

        DispatchQueue.main.async {
            self.scheduler.scheduleUpload(pingType: pingType) {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }
    
    public func recordSessionStart() throws {
        if !configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        try pingBuilder.startSession()
    }
    
    public func recordSessionEnd() throws {
        if !configuration.isCollectionEnabled {
            return
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        try pingBuilder.endSession()
    }
    
    public func recordDefaultSearchProviderChange(searchEngine: String) throws {
        if !configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        pingBuilder.changeDefaultSearch(searchEngine: searchEngine)
    }
    
    public func recordSearch(location: String, searchEngine: String) throws {
        if !configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.WrongConfiguration, userInfo: [NSLocalizedDescriptionKey: "This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)"])
        }
        
        pingBuilder.search(location: location, searchEngine: searchEngine)
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
