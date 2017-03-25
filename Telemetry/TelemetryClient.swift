//
//  TelemetryClient.swift
//  Telemetry
//
//  Created by Justin D'Arcangelo on 3/22/17.
//
//

import Foundation

public class TelemetryClient: NSObject {
    private let sessionConfiguration: URLSessionConfiguration
    private let operationQueue: OperationQueue
    
    fileprivate var response: URLResponse?
    fileprivate var handler: (URLResponse?, Data?, Error?) -> Void
    
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
        self.handler = {_,_,_ in}
    }
    
    public func send(request: URLRequest, completionHandler: @escaping (URLResponse?, Data?, Error?) -> Void) {
        self.handler = completionHandler

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
        guard let error = error else { return }

        self.handler(self.response, nil, error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.handler(self.response, data, nil)
    }
}
