//
//  TelemetryClient.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/22/17.
//
//

import Foundation

public class TelemetryClient: NSObject {
    private let configuration: TelemetryConfiguration

    public init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
    }
    
    public func upload(ping: TelemetryPing, completionHandler: @escaping (Error?) -> Void) -> Void {
        guard let url = URL(string: "\(configuration.serverEndpoint)\(ping.uploadPath)") else {
            let error = NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.InvalidUploadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL: \(configuration.serverEndpoint)\(ping.uploadPath)"])
            
            print(error.localizedDescription)
            completionHandler(error)
            return
        }
        
        guard let data = ping.measurementsJSON() else {
            let error = NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.CannotGenerateJSON, userInfo: [NSLocalizedDescriptionKey: "Error generating JSON data for TelemetryPing"])

            print(error.localizedDescription)
            completionHandler(error)
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = data

        print("\(request.httpMethod ?? "(GET)") \(request.debugDescription)\nRequest Body: \(String(data: data, encoding: .utf8) ?? "(nil)")")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completionHandler(nil)
                return
            }

            let err = error ?? NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.UnknownUploadError, userInfo: nil)
            completionHandler(err)
        }
        task.resume()
    }
}

