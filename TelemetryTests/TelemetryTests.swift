//
//  TelemetryTests.swift
//  TelemetryTests
//
//  Created by Justin D'Arcangelo on 3/13/17.
//
//

import XCTest
import OHHTTPStubs

@testable import Telemetry

class TelemetryTests: XCTestCase {
    var expectation: XCTestExpectation? = nil

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            let body = (data as NSURLRequest).ohhttpStubs_HTTPBody()
            let str = String(data: body!, encoding: .utf8) ?? ""
            print(" -- \n \(str)")
            let json = try! JSONSerialization.jsonObject(with: body!, options: []) as? [String: Any]

            self.expectation?.fulfill()
            return OHHTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTelemetryUpload() {
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "AppInfo.displayName"
        telemetryConfig.userDefaultsSuiteName = "AppInfo.sharedContainerIdentifier"
        telemetryConfig.dataDirectory = .documentDirectory
        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)

        Telemetry.default.recordSessionStart()
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
        Telemetry.default.recordSessionEnd()

        Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)

        expectation = expectation(description: "Completed upload")

//        Telemetry.default.scheduleUpload { (data, error) in
//            let json = JSON(data ?? Data())
//
//            XCTAssert(error == nil, "Received didUpload(...) callback without an error")
//            XCTAssert(json["foo"] == "bar", "Received didUpload(...) callback with expected JSON result")
//
//            callback.fulfill()
//        }

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
