//
//  TelemetryEvent.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class TelemetryEvent {
    public static let MaxLengthCategory = 30
    public static let MaxLengthMethod = 20
    public static let MaxLengthObject = 20
    public static let MaxLengthValue = 80

    public static let MaxNumberOfExtras = 10
    public static let MaxLengthExtraKey = 15
    public static let MaxLengthExtraValue = 80
    
    private static let AppLaunchTimestamp: Date = Date()
    
    public let category: String
    public let method: String
    public let object: String?
    public let value: String?
    
    public let timestamp: UIntMax
    
    private var extras: [String : String]
    
    public convenience init(category: String, method: String, object: String?, value: String?) {
        self.init(category: category, method: method, object: object, value: value, timestamp: UIntMax(Date().timeIntervalSince(type(of: self).AppLaunchTimestamp) * 1000), extras: [:])
    }
    
    private init(category: String, method: String, object: String?, value: String?, timestamp: UIntMax, extras: [String : String]) {
        self.category = TelemetryUtils.truncate(string: category, maxLength: TelemetryEvent.MaxLengthCategory)!
        self.method = TelemetryUtils.truncate(string: method, maxLength: TelemetryEvent.MaxLengthMethod)!
        self.object = TelemetryUtils.truncate(string: object, maxLength: TelemetryEvent.MaxLengthObject)
        self.value = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthValue)

        self.timestamp = timestamp
        
        self.extras = extras
    }
    
    public static func from(array: [Any?]) -> TelemetryEvent? {
        var event: TelemetryEvent? = nil

        if array.count >= 4 {
            if let timestamp = array[0] as? UIntMax,
                let category = array[1] as? String,
                let method = array[2] as? String,
                let object = array[3] as? String {
                
                if array.count == 4 {
                    event = TelemetryEvent(category: category, method: method, object: object, value: nil, timestamp: timestamp, extras: [:])
                } else if array.count == 5 {
                    if let value = array[4] as? String {
                        event = TelemetryEvent(category: category, method: method, object: object, value: value, timestamp: timestamp, extras: [:])
                    }
                } else if array.count >= 6 {
                    if let value = array[4] as? String, let extras = array[5] as? [String : String] {
                        event = TelemetryEvent(category: category, method: method, object: object, value: value, timestamp: timestamp, extras: extras)
                    }
                }
            }
        }
        
        return event
    }

    public func addExtra(key: String, value: String) {
        if extras.count >= TelemetryEvent.MaxNumberOfExtras {
            print("Exceeded maximum limit of \(TelemetryEvent.MaxNumberOfExtras) TelemetryEvent extras")
            return
        }

        let truncatedKey = TelemetryUtils.truncate(string: key, maxLength: TelemetryEvent.MaxLengthExtraKey)
        let truncatedValue = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthExtraValue)
        
        extras[truncatedKey!] = truncatedValue
    }

    public func toArray() -> [Any?] {
        var array: [Any?] = [timestamp, category, method, object]
        
        if value != nil {
            array.append(value)
        }
        
        if !extras.isEmpty {
            if value == nil {
                array.append(nil)
            }
            
            array.append(extras)
        }
        
        return array
    }
    
    public func toJSON() -> Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: toArray(), options: [])
            return jsonData
        } catch let error {
            print("Error serializing TelemetryEvent to JSON: \(error)")
            return nil
        }
    }
}
