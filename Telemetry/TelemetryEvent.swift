//
//  TelemetryEvent.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class TelemetryEvent {
    var name: String
    var method: String
    var extras: Dictionary<String, Any>
    
    init(name: String, method: String, extras: Dictionary<String, Any>) {
        self.name = name
        self.method = method
        self.extras = extras
    }
}
