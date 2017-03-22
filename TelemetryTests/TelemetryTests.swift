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
    
    func testTelemetryUpload() {
        let callback = expectation(description: "Completed upload")

        Telemetry.default.scheduleUpload { (data, error) in
            let json = JSON(data ?? Data())
            
            XCTAssert(error == nil, "Received didUpload(...) callback without an error")
            XCTAssert(json["foo"] == "bar", "Received didUpload(...) callback with expected JSON result")
            
            callback.fulfill()
        }
        
        waitForExpectations(timeout: 60.0) { error in
            if error != nil {
                print("Test timed out waiting for upload: %@", error!)
                return
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
