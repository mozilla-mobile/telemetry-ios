//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation
import UIKit

public typealias BeforeSerializePingHandler = ([String: Any?]) -> [String: Any?]

public class Telemetry {
    public let configuration: TelemetryConfiguration
    
    private let storage: TelemetryStorage
    private let scheduler: TelemetryScheduler

    private var beforeSerializePingHandlers = [String : [BeforeSerializePingHandler]]()
    private var pingBuilders = [String : TelemetryPingBuilder]()
    private var backgroundTasks = [String : UIBackgroundTaskIdentifier]()

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
    }
    
    public func add<T: TelemetryPingBuilder>(pingBuilderType: T.Type) {
        let pingBuilder = pingBuilderType.init(configuration: configuration, storage: storage)
        pingBuilders[pingBuilderType.PingType] = pingBuilder
        backgroundTasks[pingBuilderType.PingType] = UIBackgroundTaskInvalid
    }

    public func hasPingType(_ pingType: String) -> Bool {
        return pingBuilders[pingType] != nil
    }

    public func forEachPingType(_ iterator: (String) -> Void) {
        for (pingType, _) in pingBuilders {
            iterator(pingType)
        }
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
            guard pingBuilder.canBuild else {
                return
            }

            let ping = pingBuilder.build(usingHandlers: self.beforeSerializePingHandlers[pingType])
            self.storage.enqueue(ping: ping)
        }
    }

    public func scheduleUpload(pingType: String) {
        guard configuration.isUploadEnabled,
            let backgroundTask = backgroundTasks[pingType],
            backgroundTask == UIBackgroundTaskInvalid else {
            return
        }

        backgroundTasks[pingType] = UIApplication.shared.beginBackgroundTask(withName: "MozTelemetryUpload-\(pingType)") {
            print("Background task 'MozTelemetryUpload-\(pingType)' is expiring")

            if let backgroundTask = self.backgroundTasks[pingType] {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }

            self.backgroundTasks[pingType] = UIBackgroundTaskInvalid
        }

        DispatchQueue.main.async {
            self.scheduler.scheduleUpload(pingType: pingType) {
                if let backgroundTask = self.backgroundTasks[pingType] {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                }

                self.backgroundTasks[pingType] = UIBackgroundTaskInvalid
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

            if pingBuilder.numberOfEvents >= self.configuration.maximumNumberOfEventsPerPing {
                self.queue(pingType: FocusEventPingBuilder.PingType)
            }
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

    // To modify the final key-value data dict before it gets stored as JSON, install a handler using this func.
    public func beforeSerializePing(pingType: String, handler: @escaping BeforeSerializePingHandler) {
        if beforeSerializePingHandlers[pingType] == nil {
            beforeSerializePingHandlers[pingType] = [BeforeSerializePingHandler]()
        }
        beforeSerializePingHandlers[pingType]?.append(handler)
    }
}
