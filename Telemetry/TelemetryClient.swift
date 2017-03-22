//
//  TelemetryClient.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/22/17.
//
//

import Foundation

public protocol TelemetryClientDelegate {
    func telemetryClient(_ client: TelemetryClient, didComplete request: URLRequest, response: URLResponse?, data: Data?)
    func telemetryClient(_ client: TelemetryClient, didFail request: URLRequest, response: URLResponse?, error: Error?)
}

public class TelemetryClient: NSObject {
    private let sessionConfiguration: URLSessionConfiguration
    private let operationQueue: OperationQueue
    
    fileprivate var request: URLRequest?
    fileprivate var response: URLResponse?
    
    public var delegate: TelemetryClientDelegate?
    
    public override init() {
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
    }
    
    public func send(request: URLRequest) {
        self.request = request

        let session = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
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
        guard let request = self.request else {
            return
        }

        if error != nil {
            self.delegate?.telemetryClient(self, didFail: request, response: self.response, error: error)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let request = self.request else {
            return
        }

        self.delegate?.telemetryClient(self, didComplete: request, response: self.response, data: data)
    }
}
