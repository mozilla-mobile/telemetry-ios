/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import OHHTTPStubs

@testable import Telemetry

class TelemetryTests: XCTestCase {
    var expectation: XCTestExpectation? = nil

    override func setUp() {
        super.setUp()

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "AppInfo.displayName"
        telemetryConfig.userDefaultsSuiteName = "AppInfo.sharedContainerIdentifier"
        telemetryConfig.dataDirectory = .documentDirectory

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)

        Telemetry.default.forEachPingType { t in
            Telemetry.default.storage.clear(pingType: t)
            Telemetry.default.storage.set(key: "\(t)-lastUploadTimestamp", value: 0)
            Telemetry.default.storage.set(key: "\(t)-dailyUploadCount", value: 0)

            Telemetry.default.storage.deleteEventArrayFile(forPingType: t)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func setupHttpErrorStub(expectedFilesUploaded: Int, statusCode: URLError.Code = URLError.Code.badServerResponse) {
        var countFilesUploaded = 0

        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            countFilesUploaded += 1
            if expectedFilesUploaded == countFilesUploaded {
                DispatchQueue.main.async {
                    self.expectation?.fulfill()
                }
            }

            let err = NSError(domain: NSURLErrorDomain, code: statusCode.rawValue, userInfo: nil)
            return OHHTTPStubsResponse(error: err)
        }
    }

    private func setupHttpResponseStub(expectedFilesUploaded: Int, statusCode: Int32 = 200, eventCount: Int = 0) {
        var countFilesUploaded = 0

        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            let body = (data as NSURLRequest).ohhttpStubs_HTTPBody()
            let str = String(data: body!, encoding: .utf8) ?? ""
            print("STUB RECEIVED: \(str) \n")
            let json = try! JSONSerialization.jsonObject(with: body!, options: []) as? [String: Any]
            XCTAssert(json != nil)
            if eventCount > 0 {
                XCTAssert((json!["events"] as! [[Any]]).count == eventCount)
            }

            countFilesUploaded += 1
            if expectedFilesUploaded == countFilesUploaded {
                DispatchQueue.main.async {
                    // let the response get processed before we mark the expectation fulfilled
                    self.expectation?.fulfill()
                }
            }

            return OHHTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: statusCode, headers: ["Content-Type": "application/json"])
        }
    }

    private func upload(pingType: String) {
        expectation = expectation(description: "Completed upload")
        Telemetry.default.scheduleUpload(pingType: pingType)
        waitForExpectations(timeout: 10.0) { error in
            if error != nil {
                print("Test timed out waiting for upload: \(error!)")
            }
        }
    }

    private func storeOnDiskAndUpload(corePingFilesToWrite: Int) {
        for _ in 0..<corePingFilesToWrite {
            Telemetry.default.recordSessionStart()
            Telemetry.default.recordSessionEnd()
            Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        }

        waitForFilesOnDisk(count: corePingFilesToWrite)
        upload(pingType: CorePingBuilder.PingType)
    }

    private func waitForFilesOnDisk(count: Int, pingType: String = CorePingBuilder.PingType) {
        wait()
        XCTAssert(countFilesOnDisk(forPingType: pingType) == count, "waitForFilesOnDisk matching")
    }

    private func wait() {
        let wait = expectation(description: "process async events")
        XCTWaiter().wait(for: [wait], timeout: 0.25)
        wait.fulfill()
    }

    func testAppEvents() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
        Telemetry.default.recordEvent(category: "category", method: "method", object: "object", value: "value", extras: ["extraKey": "extraValue"])
        Telemetry.default.recordEvent(category: "category", method: "method", object: "object", value: "value", extras: ["extraKey": nil])
        Telemetry.default.recordEvent(category: "category", method: "method", object: "object", value: nil, extras: ["extraKey": nil])

        // Write events to a file
        Telemetry.default.queue(pingType: FocusEventPingBuilder.PingType)
        waitForFilesOnDisk(count: 1, pingType: FocusEventPingBuilder.PingType)

        setupHttpResponseStub(expectedFilesUploaded: 1, statusCode: 200, eventCount: 4)
        upload(pingType: FocusEventPingBuilder.PingType)
    }

    func testNoInternet() {
        serverError(code: URLError.notConnectedToInternet)
    }

    func test5xxCode() {
        serverError(code: URLError.Code.badServerResponse)
    }

    private func countFilesOnDisk(forPingType pingType: String = CorePingBuilder.PingType) -> Int {
        var result = 0
        let seq = Telemetry.default.storage.sequence(forPingType: pingType)
        while seq.next() != nil {
            result += 1
        }
        return result
    }

    private func serverError(code: URLError.Code) {
        setupHttpErrorStub(expectedFilesUploaded: 1, statusCode: code)
        let filesOnDisk = 3
        // Only one attempted upload, but all 3 files should remain on disk.
        storeOnDiskAndUpload(corePingFilesToWrite: filesOnDisk)
        waitForFilesOnDisk(count: filesOnDisk)
    }

    func test4xxCode() {
        setupHttpResponseStub(expectedFilesUploaded: 3, statusCode: 400)
        storeOnDiskAndUpload(corePingFilesToWrite: 3)
        waitForFilesOnDisk(count: 0)
    }

    func testTelemetryUpload() {
        setupHttpResponseStub(expectedFilesUploaded: 3, statusCode: 200)
        storeOnDiskAndUpload(corePingFilesToWrite: 3)
        waitForFilesOnDisk(count: 0)
    }

    func testFileTimestamp() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let fileDate = TelemetryStorage.extractTimestampFromName(pingFile: URL(string: "a/b/c/foo-t-\(lastWeek.timeIntervalSince1970).json")!)!
        XCTAssert(fileDate.timeIntervalSince1970 > 0)
        XCTAssert(fabs(fileDate.timeIntervalSince1970 - lastWeek.timeIntervalSince1970) < 0.1 /* epsilon */)
        XCTAssert(TelemetryUtils.daysBetween(start: fileDate, end: Date()) == 7)
    }
}

