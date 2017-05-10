//
//  TelemetryClient.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/22/17.
//
//

import Foundation

public class TelemetryClient: NSObject {
    private static let sessionConfiguration: URLSessionConfiguration = {
        #if DEBUG
            // Cannot intercept background HTTP request using OHHTTPStubs in test environment.
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                return URLSessionConfiguration.default
            }
        #endif
        
        return URLSessionConfiguration.background(withIdentifier: "MozTelemetry")
    }()

    private let configuration: TelemetryConfiguration

    private let operationQueue: OperationQueue

    fileprivate var completionHandler: (Error?) -> Void

    fileprivate var response: URLResponse?
    
    lazy private var session: URLSession = URLSession(configuration: TelemetryClient.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
    
    public init(configuration: TelemetryConfiguration) {
        self.configuration = configuration

        self.operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        self.completionHandler = {_ in}
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

        self.completionHandler = completionHandler
        
        var request = URLRequest(url: url)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = data

        print("\(request.httpMethod ?? "(GET)") \(request.debugDescription)\nRequest Body: \(String(data: data, encoding: .utf8) ?? "(nil)")")

        let task = session.dataTask(with: request)
        task.resume()
    }
}

extension TelemetryClient: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        completionHandler(URLSession.ResponseDisposition.allow)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            completionHandler(error)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        completionHandler(nil)
    }
}
