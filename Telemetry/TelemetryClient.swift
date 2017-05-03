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

    private let sessionConfiguration: URLSessionConfiguration
    private let operationQueue: OperationQueue
    
    fileprivate var completionHandler: (Error?) -> Void
    
    fileprivate var response: URLResponse?
    
    public init(configuration: TelemetryConfiguration) {
        self.configuration = configuration

        #if DEBUG
            // Cannot intercept background HTTP request using OHHTTPStubs in test environment.
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                self.sessionConfiguration = URLSessionConfiguration.default
            } else {
                self.sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "MozTelemetry")
            }
        #else
            self.sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "MozTelemetry")
        #endif

        self.operationQueue = OperationQueue()
        
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

        print("TelemetryClient.upload() Sending URLRequest: \(request.httpMethod ?? "(GET)") \(request.debugDescription)")
        print("TelemetryClient.upload() Request body: \(String(data: data, encoding: .utf8) ?? "(nil)")")
        print("TelemetryClient.upload() Request headers: \(request.allHTTPHeaderFields!)")

        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: operationQueue)
        let task = session.dataTask(with: request)
        task.resume()
    }
}

extension TelemetryClient: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("URLSessionDataDelegate: didReceive response:\(response)")
        self.response = response
        completionHandler(URLSession.ResponseDisposition.allow)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("URLSessionDataDelegate: didCompleteWithError error:\(error?.localizedDescription ?? "(nil)")")
        if error != nil {
            completionHandler(error)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("URLSessionDataDelegate: didReceive data:\(String(data: data, encoding: .utf8) ?? "(nil)")")
        completionHandler(nil)
    }
}
