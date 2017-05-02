//
//  TelemetryDataStore.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class TelemetryStorage {
    private let name: String
    private let configuration: TelemetryConfiguration
    
    public init(name: String, configuration: TelemetryConfiguration) {
        self.name = name
        self.configuration = configuration
    }

    public func get(valueFor key: String) -> Any? {
        if let json = open(filename: "\(name)-values.json") {
            if let dict = json as? [String : Any?] {
                return dict[key] ?? nil
            } else {
                print("Value not found in \(name)-values.json for key '\(key)'")
            }
        } else {
            print("Unable to open \(name)-values.json")
        }
        
        return nil
    }

    public func set(key: String, value: Any?) {
        let json = open(filename: "\(name)-values.json")
        var dict = json as? [String : Any?] ?? [String : Any?]()

        dict[key] = value
        
        save(object: dict, toFile: "\(name)-values.json")
    }

    public func load(pingType: String) -> [TelemetryPing] {
        if let json = open(filename: "\(name)-\(pingType).json") {
            if let items = json as? [Any] {
                var pings: [TelemetryPing] = []
                
                for (index, item) in items.enumerated() {
                    if let dict = item as? [String : Any] {
                        if let ping = TelemetryPing.from(dictionary: dict) {
                            pings.append(ping)
                        } else {
                            print("Unable to deserialize TelemetryPing in \(name)-\(pingType).json at index \(index)")
                        }
                    } else {
                        print("Invalid TelemetryPing in \(name)-\(pingType).json at index \(index)")
                    }
                }
                
                return pings
            } else {
                print("Root array not found in \(name)-\(pingType).json")
            }
        } else {
            print("Unable to open \(name)-\(pingType).json")
        }
        
        return []
    }

    public func store(ping: TelemetryPing) {
        var dicts: [[String : Any]] = []

        var pings = load(pingType: ping.pingType)
        pings.append(ping)
        
        for ping in pings {
            dicts.append(ping.toDictionary())
        }
        
        save(object: dicts, toFile: "\(name)-\(ping.pingType).json")
    }
    
    private func open(filename: String) -> Any? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(filename)
            let data = try Data(contentsOf: url)

            print("Opened \(url)")
            
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    private func save(object: Any, toFile filename: String) {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename)
            
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(toFile: url.path, atomically: true, encoding: .utf8)
            } else {
                print("ERROR: Unable to generate JSON data")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
