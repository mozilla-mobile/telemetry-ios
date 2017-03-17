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

class TelemetryTests: XCTestCase, TelemetryDelegate {
    
    var didUploadExpectation: XCTestExpectation?
    var didUploadResult: Data?
    var didUploadError: Error?
    
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
        didUploadExpectation = expectation(description: "Completed upload")

        let telemetry = Telemetry(storageName: "TelemetryTests")
        telemetry.delegate = self
        telemetry.scheduleUpload()
        
        waitForExpectations(timeout: 60.0) { error in
            if error != nil {
                print("Test timed out waiting for upload: %@", error!)
                return
            }
    
            let json = JSON(self.didUploadResult ?? Data())
            
            XCTAssert(self.didUploadError == nil, "Received didUpload(...) callback without an error")
            XCTAssert(json["foo"] == "bar", "Received didUpload(...) callback with expected JSON result")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func didUpload(result: Data?, error: Error?) {
        didUploadResult = result
        didUploadError = error
        didUploadExpectation?.fulfill()
    }
    
}
