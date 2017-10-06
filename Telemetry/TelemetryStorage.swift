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

    private func listFilesFromStorageFolder () -> [String]? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return nil
        }
    }

    typealias PingFile = (filename: String, dicts: [[String : Any]])
    func readAllFilesReadyForUpload(pingType: String) -> [PingFile] {
        var result = [PingFile]()
        let files = listFilesFromStorageFolder()
        files?.forEach { file in
            if file.hasPrefix("\(name)-\(pingType)-") && file.hasSuffix(".json") {
                if let json = open(filename: file), let dicts = json as? [[String : Any]] {
                    result.append((file, dicts))
                }
            }
        }

        return result
    }

    func markPingFileReadyForUpload(pingType: String) {
        let time = Date().timeIntervalSince1970
        let origName = "\(name)-\(pingType).json"
        let newName = "\(name)-\(pingType)-\(time).json"
        do {
             let old = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(origName)

            let path = NSSearchPathForDirectoriesInDomains(configuration.dataDirectory, .userDomainMask, true)[0]
            let documentDirectory = URL(fileURLWithPath: path)
            let new = documentDirectory.appendingPathComponent(newName)

            try FileManager.default.moveItem(at: old, to: new)
        } catch {
            print(error)
        }
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

    // Write the dicts to the named file, or if the dicts is empty, deletes the file.
    func writeOrDelete(file: String, dicts: [[String : Any?]]) {
        if dicts.count < 1 {
            do {
                let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(file)
                try FileManager.default.removeItem(at: url)
            }
            catch {
                print(error)
            }

            return
        }
        save(object: dicts, toFile: file)
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
