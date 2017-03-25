//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation
import SwiftyJSON

public class Telemetry {
    private let storage: TelemetryStorage
    private let corePing: TelemetryCorePing
    
    static public let `default`: Telemetry = {
        return Telemetry(storageName: "MozTelemetry")
    }()
    
    public init(storageName: String) {
        self.storage = TelemetryStorage(name: storageName)
        self.corePing = TelemetryCorePing(storage: self.storage)
    }
    
    public func queueCorePing() {
        self.storage.store(ping: self.corePing)
    }
    
    public func queueEvent(event: TelemetryEvent) {
        
    }
    
    public func scheduleUpload(completionHandler: @escaping (Data?, Error?)->Void = {_,_ in }) {
        DispatchQueue.main.async {
            self.upload(completionHandler: completionHandler)
        }
    }
    
    public func recordSessionStart() {
        self.corePing.startSession()
    }
    
    public func recordSessionEnd() {
        self.corePing.endSession()
    }
    
    private func upload(completionHandler: @escaping (Data?, Error?)->Void = {_,_ in }) {
        let client = TelemetryClient()
        guard let url = URL(string: "https://incoming.telemetry.mozilla.org") else { completionHandler(nil, nil) ; return }
        client.send(request: URLRequest(url: url)) { (response, data, error) in
            if error != nil {
                completionHandler(nil, error)
                return
            }

            completionHandler(data, nil)
        }
    }
}
