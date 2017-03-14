//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class Telemetry {
    private let storage: TelemetryStorage
    private let corePing: TelemetryCorePing
    
    public init(storageName: String) {
        self.storage = TelemetryStorage(name: storageName)
        self.corePing = TelemetryCorePing(storage: self.storage)
    }
    
    public func queueCorePing() {
        self.storage.store(ping: self.corePing)
    }
    
    public func queueEvent(event: TelemetryEvent) {
        
    }
    
    public func scheduleUpload() {
        
    }
    
    public func recordSessionStart() {
        self.corePing.startSession()
    }
    
    public func recordSessionEnd() {
        self.corePing.endSession()
    }
}
