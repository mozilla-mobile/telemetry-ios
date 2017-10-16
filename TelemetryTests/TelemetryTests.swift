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
    var expectedFilesUploaded = 0
    var countFilesUploaded = 0

    override func setUp() {
        super.setUp()

        expectedFilesUploaded = 0
        countFilesUploaded = 0

        // Put setup code here. This method is called before the invocation of each test method in the class.
        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            let body = (data as NSURLRequest).ohhttpStubs_HTTPBody()
            let str = String(data: body!, encoding: .utf8) ?? ""
            print(" -- \n \(str)")
            let _ = try! JSONSerialization.jsonObject(with: body!, options: []) as? [String: Any]

            self.countFilesUploaded += 1
            if self.expectedFilesUploaded == self.countFilesUploaded {
                self.expectation?.fulfill()
            }
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

        expectedFilesUploaded = 3

        for _ in 0..<expectedFilesUploaded {
            Telemetry.default.recordSessionStart()
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
            Telemetry.default.recordSessionEnd()
            Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        }

        let wait = expectation(description: "process async events")
        XCTWaiter().wait(for: [wait], timeout: 1)
        for _ in 0..<expectedFilesUploaded {
            XCTAssert(Telemetry.default.storage.sequenceForPingType(CorePingBuilder.PingType).next() != nil, "Confirm upload file exists")
        }
        wait.fulfill() // required so it doesn't intefere with waitForExpectations

        expectation = expectation(description: "Completed upload")
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)

        waitForExpectations(timeout: 10.0) { error in
            if error != nil {
                print("Test timed out waiting for upload: %@", error!)
                return
            }
        }

        XCTWaiter().wait(for: [expectation(description: "process async events")], timeout: 1)
        XCTAssert(Telemetry.default.storage.sequenceForPingType(CorePingBuilder.PingType).next() == nil, "Confirm no more upload files")
    }
}

