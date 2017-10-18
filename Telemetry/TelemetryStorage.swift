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
    private let configuration: TelemetryConfiguration

    private var currentPing: TelemetryPing?
    private var currentPingFile: URL?

    init(directoryEnumerator: FileManager.DirectoryEnumerator?, configuration: TelemetryConfiguration) {
        self.directoryEnumerator = directoryEnumerator
        self.configuration = configuration
    }

    func isStale(pingFile: URL) -> Bool {
        guard let time = TelemetryStorage.extractTimestampFromName(pingFile: pingFile) else {
            return false
        }

        let days = TelemetryUtils.daysBetween(start: time, end: Date())
        return days > configuration.maximumAgeOfPingInDays
    }

    func next() -> TelemetryPing? {
        guard let directoryEnumerator = self.directoryEnumerator else {
            return nil
        }

        while let url = directoryEnumerator.nextObject() as? URL {
            if isStale(pingFile: url) {
                remove(pingFile: url)
                continue
            }

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
            remove(pingFile: url)
        }

        currentPingFile = nil
        return nil
    }

    func remove() {
        guard let currentPingFile = self.currentPingFile else {
            return
        }

        remove(pingFile: currentPingFile)
    }

    private func remove(pingFile: URL) {
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
        guard let directory = directory(forPingType: ping.pingType) else {
            print("TelemetryStorage.enqueue(): Could not get directory for pingType '\(ping.pingType)'")
            return
        }

        var url = directory.appendingPathComponent("-t-\(Date().timeIntervalSince1970).json")

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
    
    func sequence(forPingType pingType: String) -> TelemetryStorageSequence {
        guard let directory = directory(forPingType: pingType) else {
            print("TelemetryStorage.sequenceForPingType(): Could not get directory for pingType '\(pingType)'")
            return TelemetryStorageSequence(directoryEnumerator: nil, configuration: configuration)
        }
        
        let directoryEnumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: nil)
        return TelemetryStorageSequence(directoryEnumerator: directoryEnumerator, configuration: configuration)
    }

    private func directory(forPingType pingType: String) -> URL? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name)-\(pingType)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            print("TelemetryStorage.directoryForPingType(): \(error.localizedDescription)")
            return nil
        }
    }

    func clear(pingType: String) {
        guard let url = directory(forPingType: pingType) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        }
        catch {
            print("\(#function) \(error)")
        }
    }

    class func extractTimestampFromName(pingFile: URL) -> Date? {
        let str = pingFile.absoluteString
        let pat = "-t-([\\d.]+)\\.json"
        let regex = try? NSRegularExpression(pattern: pat, options: [])
        assert(regex != nil)
        if let result = regex?.matches(in:str, range:NSMakeRange(0, str.characters.count)),
            let match = result.first, match.range.length > 0 {
            let time = (str as NSString).substring(with: match.rangeAt(1))
            if let time = Double(time) {
                return Date(timeIntervalSince1970: time)
            }
        }
        return nil
    }


}
