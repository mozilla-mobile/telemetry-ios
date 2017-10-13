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

    // Use this to monitor upload errors from outside of this library
    public static let notificationUploadError = Notification.Name("NotificationTelemetryUploadError")

    public static let `default`: Telemetry = {
        return Telemetry(storageName: "MozTelemetry-Default")
    }()

    let app = AppEvents()
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
    
    public func queue(pingType: String) {
        if !self.configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder = self.pingBuilders[pingType] else {
            print("This configuration does not contain a TelemetryPingBuilder for \(pingType)")
            return
        }
        
        DispatchQueue.main.async {
            if !pingBuilder.canBuild {
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
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "MozTelemetryUpload-\(pingType)") {
            print("Background task 'MozTelemetryUpload-\(pingType)' is expiring")
            
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
    
    public func recordSessionStart() {
        if !configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }
        
        pingBuilder.startSession()
    }
    
    public func recordSessionEnd() {
        if !configuration.isCollectionEnabled {
            return
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }
        
        pingBuilder.endSession()
    }
    
    public func recordEvent(_ event: TelemetryEvent) {
        if !self.configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: FocusEventPingBuilder = self.pingBuilders[FocusEventPingBuilder.PingType] as? FocusEventPingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(FocusEventPingBuilder.PingType)")
            return
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
    
    public func recordEvent(category: String, method: String, object: String) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object))
    }
    
    public func recordEvent(category: String, method: String, object: String, value: String?) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object, value: value))
    }
    
    public func recordEvent(category: String, method: String, object: String, value: String?, extras: [String : Any?]?) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object, value: value, extras: extras))
    }
    
    public func recordSearch(location: SearchesMeasurement.SearchLocation, searchEngine: String) {
        if !configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }
        
        pingBuilder.search(location: location, searchEngine: searchEngine)
    }
}
