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
    
    public let category: String
    public let method: String
    public let object: String?
    public let value: String?
    
    private var extras: [String : String]
    
    init(category: String, method: String, object: String?, value: String?) {
        self.category = TelemetryUtils.truncate(string: category, maxLength: TelemetryEvent.MaxLengthCategory)!
        self.method = TelemetryUtils.truncate(string: method, maxLength: TelemetryEvent.MaxLengthMethod)!
        self.object = TelemetryUtils.truncate(string: object, maxLength: TelemetryEvent.MaxLengthObject)
        self.value = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthValue)

        self.extras = [:]
    }
    
    public func addExtra(key: String, value: String) throws {
        if extras.count >= TelemetryEvent.MaxNumberOfExtras {
            throw NSError(domain: Telemetry.ErrorDomain, code: Telemetry.ErrorTooManyEventExtras, userInfo: [NSLocalizedDescriptionKey: "Exceeded maximum limit of \(TelemetryEvent.MaxNumberOfExtras) TelemetryEvent extras"])
        }

        let truncatedKey = TelemetryUtils.truncate(string: key, maxLength: TelemetryEvent.MaxLengthExtraKey)
        let truncatedValue = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthExtraValue)
        
        extras[truncatedKey!] = truncatedValue
    }
}
