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

    private let files: [URL]
    
    private var index = -1

    private var currentPing: TelemetryPing?
    private var currentPingFile: URL?

    init(files: [URL]) {
        self.files = files
    }

    func next() -> TelemetryPing? {
        index += 1

        while files.count > index {
            let url = files[index]
            
            var isDirectory: ObjCBool = false

            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                index += 1
                continue
            }

            currentPingFile = url

            do {
                let data = try Data(contentsOf: url)
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                    let ping = TelemetryPing.from(dictionary: dict) {
                    return ping
                } else {
                    print("TelemetryStorageSequence.next(): Unable to deserialize JSON in file \(url.absoluteString)")
                }
            } catch {
                print("TelemetryStorageSequence.next(): \(error.localizedDescription) (\(url))")
            }

            // If we get here without returning a ping, something went wrong that
            // is unrecoverable and we should just delete the file.
            remove()

            // Bump the index since we didn't return a ping so we can try getting
            // the next ping file if one exists.
            index += 1
        }

        currentPingFile = nil
        return nil
    }

    func remove() {
        guard let currentPingFile = self.currentPingFile else {
            return
        }

        do {
            try FileManager.default.removeItem(at: currentPingFile)
        } catch {
            print("TelemetryStorageSequence.removePingFile(\(currentPingFile.absoluteString)): \(error.localizedDescription)")
        }
    }

    func moveToRetryDirectory() {
        guard let currentPingFile = self.currentPingFile else {
            return
        }

        let queueDirectory = currentPingFile.deletingLastPathComponent()
        let retryDirectory = queueDirectory.appendingPathComponent("retry", isDirectory: true)

        let retryPingFile = retryDirectory.appendingPathComponent(currentPingFile.lastPathComponent)

        do {
            try FileManager.default.createDirectory(at: retryDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.moveItem(at: currentPingFile, to: retryPingFile)
        } catch {
            print("TelemetryStorageSequence.moveToRetryDirectory(): \(error.localizedDescription)")
            remove()
            return
        }
    }
}

public class TelemetryStorage {
    private let name: String
    private let configuration: TelemetryConfiguration

    // Prepend to all key usage to avoid UserDefaults name collisions
    private let keyPrefix = "telemetry-key-prefix-"

    public init(name: String, configuration: TelemetryConfiguration) {
        self.name = name
        self.configuration = configuration
    }

    public func get(valueFor key: String) -> Any? {
        return UserDefaults.standard.object(forKey: keyPrefix + key)
    }

    public func set(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: keyPrefix + key)
    }

    public func enqueue(ping: TelemetryPing) {
        guard let directory = queueDirectoryForPingType(ping.pingType) else {
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

    func sequenceForPingType(_ pingType: String, includeRetryPings: Bool = false) -> TelemetryStorageSequence {
        guard let queueDirectory = queueDirectoryForPingType(pingType) else {
            print("TelemetryStorage.sequenceForPingType(): Could not get queue directory for pingType '\(pingType)'")
            return TelemetryStorageSequence(files: [])
        }

        do {
            let queueFiles = try FileManager.default.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            if includeRetryPings {
                if let retryDirectory = retryDirectoryForPingType(pingType) {
                    do {
                        let retryFiles = try FileManager.default.contentsOfDirectory(at: retryDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        return TelemetryStorageSequence(files: retryFiles + queueFiles)
                    } catch {
                        print("TelemetryStorage.sequenceForPingType(): Could not get files in retry directory '\(retryDirectory)'")
                    }
                } else {
                    print("TelemetryStorage.sequenceForPingType(): Could not get retry directory for pingType '\(pingType)'")
                }
            }
            
            return TelemetryStorageSequence(files: queueFiles)
        } catch {
            print("TelemetryStorage.sequenceForPingType(): Could not get files in queue directory '\(queueDirectory)'")
            return TelemetryStorageSequence(files: [])
        }
    }

    private func queueDirectoryForPingType(_ pingType: String) -> URL? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name)-\(pingType)", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            print("TelemetryStorage.queueDirectoryForPingType(): \(error.localizedDescription)")
            return nil
        }
    }

    private func retryDirectoryForPingType(_ pingType: String) -> URL? {
        guard let queueDirectory = queueDirectoryForPingType(pingType) else {
            return nil
        }

        do {
            let url = queueDirectory.appendingPathComponent("retry", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            print("TelemetryStorage.retryDirectoryForPingType(): \(error.localizedDescription)")
            return nil
        }
    }
}
