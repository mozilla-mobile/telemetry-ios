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
    public let object: String
    public let value: String?
    
    public let timestamp: UInt64
    
    private var extras: [String : String]
    
    public convenience init(category: String, method: String, object: String, value: String? = nil, extras: [String : Any?]? = nil) {
        let timestamp = UInt64(max(0, Date().timeIntervalSince(TelemetryEvent.AppLaunchTimestamp) * 1000))
        self.init(category: category, method: method, object: object, value: value, timestamp: timestamp)

        if let extras = extras {
            for (key, value) in extras {
                self.addExtra(key: key, value: value)
            }
        }
    }
    
    private init(category: String, method: String, object: String, value: String?, timestamp: UInt64) {
        self.category = TelemetryUtils.truncate(string: category, maxLength: TelemetryEvent.MaxLengthCategory)!
        self.method = TelemetryUtils.truncate(string: method, maxLength: TelemetryEvent.MaxLengthMethod)!
        self.object = TelemetryUtils.truncate(string: object, maxLength: TelemetryEvent.MaxLengthObject)!
        self.value = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthValue)

        self.timestamp = timestamp
        
        self.extras = [:]
    }

    private static func limitNumberOfItems(inDictionary dictionary: [String : String], to numberOfItems: Int) -> [String : String] {
        var result: [String : String] = [:]
        
        for (index, item) in dictionary.enumerated() {
            if index >= numberOfItems {
                break
            }
            
            result[item.key] = item.value
        }
        
        return result
    }
    
    public func addExtra(key: String, value: Any?) {
        if extras.count >= TelemetryEvent.MaxNumberOfExtras {
            print("Exceeded maximum limit of \(TelemetryEvent.MaxNumberOfExtras) TelemetryEvent extras")
            return
        }

        if let truncatedKey = TelemetryUtils.truncate(string: key, maxLength: TelemetryEvent.MaxLengthExtraKey) {
            let truncatedValue = TelemetryUtils.truncate(string: TelemetryUtils.asString(value), maxLength: TelemetryEvent.MaxLengthExtraValue)
            extras[truncatedKey] = truncatedValue
        }
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
