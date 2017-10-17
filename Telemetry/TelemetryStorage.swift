//
//  TelemetryDataStore.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

class TelemetryStorageSequence : Sequence, IteratorProtocol {
    typealias Element = TelemetryPing

    private let directoryEnumerator: FileManager.DirectoryEnumerator?

    private var currentPing: TelemetryPing?
    private var currentPingFile: URL?

    init(directoryEnumerator: FileManager.DirectoryEnumerator?) {
        self.directoryEnumerator = directoryEnumerator
    }

    func next() -> TelemetryPing? {
        guard let directoryEnumerator = self.directoryEnumerator else {
            return nil
        }

        while let url = directoryEnumerator.nextObject() as? URL {
            do {
                let data = try Data(contentsOf: url)
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                    let ping = TelemetryPing.from(dictionary: dict) {
                    currentPingFile = url
                    return ping
                } else {
                    print("TelemetryStorageSequence.next(): Unable to deserialize JSON in file \(url.absoluteString)")
                }
            } catch {
                print("TelemetryStorageSequence.next(): \(error.localizedDescription)")
            }

            // If we get here without returning a ping, something went wrong that
            // is unrecoverable and we should just delete the file.
            removePingFile(url)
        }

        currentPingFile = nil
        return nil
    }

    func remove() {
        guard let currentPingFile = self.currentPingFile else {
            return
        }

        removePingFile(currentPingFile)
    }

    private func removePingFile(_ pingFile: URL) {
        do {
            try FileManager.default.removeItem(at: pingFile)
        } catch {
            print("TelemetryStorageSequence.removePingFile(\(pingFile.absoluteString)): \(error.localizedDescription)")
        }
    }
}

public class TelemetryStorage {
    private let name: String
    private let configuration: TelemetryConfiguration

    // Prepend to all key usage to avoid UserDefaults name collisions
    private let keyPrefix = "telemetry-key-prefix-"

    init(name: String, configuration: TelemetryConfiguration) {
        self.name = name
        self.configuration = configuration
    }

    func get(valueFor key: String) -> Any? {
        return UserDefaults.standard.object(forKey: keyPrefix + key)
    }

    func set(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: keyPrefix + key)
    }

    func enqueue(ping: TelemetryPing) {
        guard let directory = directoryForPingType(ping.pingType) else {
            print("TelemetryStorage.enqueue(): Could not get directory for pingType '\(ping.pingType)'")
            return
        }

        var url = directory.appendingPathComponent("\(Date().timeIntervalSince1970).json")

        do {
            // TODO: Check `configuration.maximumNumberOfPingsPerType` and remove oldest ping if necessary.

            let jsonData = try JSONSerialization.data(withJSONObject: ping.toDictionary(), options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(to: url, atomically: true, encoding: .utf8)

                // Exclude this file from iCloud backups.
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            } else {
                print("ERROR: Unable to generate JSON data")
            }
        } catch {
            print("TelemetryStorage.enqueue(): \(error.localizedDescription)")
        }
    }
    
    func sequenceForPingType(_ pingType: String) -> TelemetryStorageSequence {
        guard let directory = directoryForPingType(pingType) else {
            print("TelemetryStorage.sequenceForPingType(): Could not get directory for pingType '\(pingType)'")
            return TelemetryStorageSequence(directoryEnumerator: nil)
        }
        
        let directoryEnumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: nil)
        return TelemetryStorageSequence(directoryEnumerator: directoryEnumerator)
    }

    private func directoryForPingType(_ pingType: String) -> URL? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name)-\(pingType)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            print("TelemetryStorage.directoryForPingType(): \(error.localizedDescription)")
            return nil
        }
    }
}
