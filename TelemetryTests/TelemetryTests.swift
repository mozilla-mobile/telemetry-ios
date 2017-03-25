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

        stub(condition: isHost("incoming.telemetry.mozilla.org")) { _ in
            return OHHTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }
    
    func testTelemetryUpload() {
        let callback = expectation(description: "Completed upload")

        Telemetry.default.scheduleUpload { (data, error) in
            guard let data = data else { XCTFail() ; return }
            let json = JSON(data)
            
            XCTAssert(error == nil, "Received didUpload(...) callback without an error")
            XCTAssert(json["foo"] == "bar", "Received didUpload(...) callback with expected JSON result")
            
            callback.fulfill()
        }
        
        waitForExpectations(timeout: 60.0) { error in
            guard let error = error else { return }
            print("Test timed out waiting for upload: %@", error)
            return
        }
    }

}
