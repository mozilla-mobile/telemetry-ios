//
//  TelemetryTests.swift
//  TelemetryTests
//
//  Created by Justin D'Arcangelo on 3/13/17.
//
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
@testable import Telemetry

class TelemetryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        stub(condition: isHost("incoming.telemetry.mozilla.org")) { _ in
            return OHHTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testHTTPRequest() {
        let expectedResult = expectation(description: "Completed HTTP request")
        let task = URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://incoming.telemetry.mozilla.org")!)) { data, response, error in
            let json = JSON(data ?? Data())

            print("data", json)
            print("response", response ?? "(none)")
            print("error", error ?? "(none)")
            
            XCTAssert(error == nil, "Received HTTP response without an error")
            XCTAssert(json["foo"] == "bar", "Received expected JSON result")

            expectedResult.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: 60.0) { error in
            if error != nil {
                print("Test timed out waiting for HTTP request: %@", error!)
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
