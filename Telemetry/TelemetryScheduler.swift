//
//  TelemetryScheduler.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 4/18/17.
//
//

import Foundation

public class TelemetryScheduler {
    private let configuration: TelemetryConfiguration
    private let storage: TelemetryStorage
    
    private let client: TelemetryClient
    
    init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.configuration = configuration
        self.storage = storage
        
        self.client = TelemetryClient(configuration: configuration)
    }
    
    public func scheduleUpload(pingType: String, completionHandler: @escaping () -> Void) {
        if !hasReachedDailyUploadLimitForPingType(pingType) {
            while let ping = storage.dequeue(pingType: pingType) {
                client.upload(ping: ping) { (error) in
                    if error != nil {
                        print("Error uploading TelemetryPing: \(error!.localizedDescription)")
                    }
                }
                
                incrementDailyUploadCountForPingType(pingType)
                
                if hasReachedDailyUploadLimitForPingType(pingType) {
                    break
                }
            }
        }
        
        completionHandler()
    }

    private func dailyUploadCountForPingType(_ pingType: String) -> Int {
        return storage.get(valueFor: "\(pingType)-dailyUploadCount") as? Int ?? 0
    }
    
    private func lastUploadTimestampForPingType(_ pingType: String) -> TimeInterval {
        return storage.get(valueFor: "\(pingType)-lastUploadTimestamp") as? TimeInterval ?? Date().timeIntervalSince1970
    }
    
    private func incrementDailyUploadCountForPingType(_ pingType: String) {
        let dailyUploadCount = dailyUploadCountForPingType(pingType) + 1
        storage.set(key: "\(pingType)-dailyUploadCount", value: dailyUploadCount)
        
        let lastUploadTimestamp = Date().timeIntervalSince1970
        storage.set(key: "\(pingType)-lastUploadTimestamp", value: lastUploadTimestamp)
    }
    
    private func hasReachedDailyUploadLimitForPingType(_ pingType: String) -> Bool {
        if !isTimestampFromToday(timestamp: lastUploadTimestampForPingType(pingType)) {
            return false
        }
        
        return dailyUploadCountForPingType(pingType) >= configuration.maximumNumberOfPingUploadsPerDay
    }
    
    private func isTimestampFromToday(timestamp: TimeInterval) -> Bool {
        let dateA = Date(timeIntervalSince1970: timestamp)
        let dayA = Calendar.current.component(.day, from: dateA)
        let monthA = Calendar.current.component(.month, from: dateA)
        let yearA = Calendar.current.component(.year, from: dateA)

        let dateB = Date()
        let dayB = Calendar.current.component(.day, from: dateB)
        let monthB = Calendar.current.component(.month, from: dateB)
        let yearB = Calendar.current.component(.year, from: dateB)
        
        return dayA == dayB && monthA == monthB && yearA == yearB
    }
}
