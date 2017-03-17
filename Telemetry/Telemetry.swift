//
//  Telemetry.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation
import SwiftyJSON

public protocol TelemetryDelegate {
    func didUpload(result: Data?, error: Error?)
}

public class Telemetry {
    private let storage: TelemetryStorage
    private let corePing: TelemetryCorePing

    public var delegate: TelemetryDelegate?
    
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
        DispatchQueue.main.async {
            self.upload()
        }
    }
    
    public func recordSessionStart() {
        self.corePing.startSession()
    }
    
    public func recordSessionEnd() {
        self.corePing.endSession()
    }
    
    private func upload() {
        let task = URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://incoming.telemetry.mozilla.org")!)) { data, response, error in
            let json = JSON(data ?? Data())
            
            print("data", json)
            print("response", response ?? "(none)")
            print("error", error ?? "(none)")
            
            self.delegate?.didUpload(result: data, error: error)
        }
        
        task.resume()
    }
}
