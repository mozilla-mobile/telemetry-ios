//
//  TelemetryDataStore.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/14/17.
//
//

import Foundation

public class TelemetryStorage {
    private let plistFile: URL
    private let dict: NSMutableDictionary
    
    public init(name: String) {
        self.plistFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(name).plist")
        
        if !FileManager.default.fileExists(atPath: self.plistFile.path) {
            self.dict = NSMutableDictionary()
            if self.dict.write(to: self.plistFile, atomically: true) {
                print("\(self.plistFile) initialized successfully")
            } else {
                print("ERROR: Unable to write to \(self.plistFile)")
            }
        } else {
            self.dict = NSMutableDictionary(contentsOf: self.plistFile) ?? NSMutableDictionary()
            print("\(self.plistFile) loaded successfully")
        }
    }
    
    func store(ping: TelemetryPing) {
        self.dict.setObject(ping.measurements, forKey: NSDate().description as NSCopying)
        print("Attempting to store TelemetryPing to plist...", self.dict)
        
        if self.dict.write(to: self.plistFile, atomically: true) {
            print("TelemetryPing written to plist successfully")
        } else {
            print("ERROR: Unable to write to \(self.plistFile)")
        }
    }
}
