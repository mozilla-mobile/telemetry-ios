//
//  TelemetryPing.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class TelemetryPing {
    let pingType: String
    let documentId: String
    let uploadPath: String
    let measurements: Dictionary<String, Any?>
    
    init(pingType: String, documentId: String, uploadPath: String, measurements: Dictionary<String, Any?>) {
        self.pingType = pingType
        self.documentId = documentId
        self.uploadPath = uploadPath
        self.measurements = measurements
    }
    
    public func toJSON() -> String? {
        let dict: Dictionary<String, Any> = ["pingType": pingType, "documentId": documentId, "uploadPath": uploadPath, "measurements": measurements]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch let error {
            print("Error serializing TelemetryPing to JSON: \(error)")
            return nil
        }
    }
}
