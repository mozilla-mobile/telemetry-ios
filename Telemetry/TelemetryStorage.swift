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
                print("TelemetryStorage.get(): Value not found in \(name)-values.json for key '\(key)'")
            }
        }
        
        return nil
    }

    public func set(key: String, value: Any?) {
        let json = open(filename: "\(name)-values.json")
        var dict = json as? [String : Any?] ?? [String : Any?]()

        dict[key] = value
        
        save(object: dict, toFile: "\(name)-values.json")
    }

    func read(pingType: String) -> [[String : Any]]? {
        if let json = open(filename: "\(name)-\(pingType).json"), let dicts = json as? [[String : Any]] {
            return dicts
        }
        return nil
    }

    func write(pingType: String, dicts: [[String : Any]]) {
        save(object: dicts, toFile: "\(name)-\(pingType).json")
    }

    public func enqueue(ping: TelemetryPing) {
        if let json = open(filename: "\(name)-\(ping.pingType).json") {
            if var dicts = json as? [[String : Any]] {
                dicts.append(ping.toDictionary())
                
                if dicts.count > configuration.maximumNumberOfPingsPerType {
                    dicts.removeFirst(dicts.count - configuration.maximumNumberOfPingsPerType)
                }
                
                save(object: dicts, toFile: "\(name)-\(ping.pingType).json")
                return
            } else {
                print("TelemetryStorage.enqueue(): Root array not found in \(name)-\(ping.pingType).json")
            }
        }
        
        save(object: [ping.toDictionary()], toFile: "\(name)-\(ping.pingType).json")
    }
    
    private func open(filename: String) -> Any? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(filename)
            let data = try Data(contentsOf: url)
            
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    private func save(object: Any, toFile filename: String) {
        do {
            var url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename)
            
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(toFile: url.path, atomically: true, encoding: .utf8)
                
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true

                try url.setResourceValues(resourceValues)
            } else {
                print("ERROR: Unable to generate JSON data")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
