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

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "AppInfo.displayName"
        telemetryConfig.userDefaultsSuiteName = "AppInfo.sharedContainerIdentifier"
        telemetryConfig.dataDirectory = .documentDirectory

        Telemetry.default.storage.clear(pingType: CorePingBuilder.PingType)
        Telemetry.default.storage.set(key: "\(CorePingBuilder.PingType)-lastUploadTimestamp", value: 0)

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func setupHttpErrorStub(statusCode: URLError.Code = URLError.Code.badServerResponse) {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            self.countFilesUploaded += 1
            if self.expectedFilesUploaded == self.countFilesUploaded {
                DispatchQueue.main.async {
                    self.expectation?.fulfill()
                }
            }

            let err = NSError(domain: NSURLErrorDomain, code: statusCode.rawValue, userInfo: nil)
            return OHHTTPStubsResponse(error: err)
        }
    }

    private func setupHttpResponseStub(statusCode: Int32 = 200) {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        stub(condition: isHost("incoming.telemetry.mozilla.org")) { data in
            let body = (data as NSURLRequest).ohhttpStubs_HTTPBody()
            let str = String(data: body!, encoding: .utf8) ?? ""
            print(" -- \n \(str)")
            let _ = try! JSONSerialization.jsonObject(with: body!, options: []) as? [String: Any]

            self.countFilesUploaded += 1
            if self.expectedFilesUploaded == self.countFilesUploaded {
                DispatchQueue.main.async {
                    // let the response get processed before we mark the expectation fulfilled
                    self.expectation?.fulfill()
                }
            }

            return OHHTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: statusCode, headers: ["Content-Type": "application/json"])
        }
    }

    private func storeOnDiskAndUpload(filesOnDisk: Int, expectedUploadCount: Int) {
        expectedFilesUploaded = expectedUploadCount

        for _ in 0..<filesOnDisk {
            Telemetry.default.recordSessionStart()
            Telemetry.default.recordSessionEnd()
            Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        }

        let wait = expectation(description: "process async events")
        XCTWaiter().wait(for: [wait], timeout: 1)
        print(countFilesOnDisk())
        XCTAssert(countFilesOnDisk() == filesOnDisk, "Confirm upload file exists")

        wait.fulfill() // required so it doesn't intefere with waitForExpectations

        expectation = expectation(description: "Completed upload")
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)

        waitForExpectations(timeout: 10.0) { error in
            if error != nil {
                print("Test timed out waiting for upload: %@", error!)
            }
        }
    }

    func testNoInternet() {
        serverError(code: URLError.notConnectedToInternet)
    }

    func test5xxCode() {
        serverError(code: URLError.Code.badServerResponse)
    }

    private func countFilesOnDisk() -> Int {
        var result = 0
        let seq = Telemetry.default.storage.sequence(forPingType: CorePingBuilder.PingType)
        while seq.next() != nil {
            result += 1
        }
        return result
    }

    private func serverError(code: URLError.Code) {
        setupHttpErrorStub(statusCode: code)
        let filesOnDisk = 3
        // Only one attempted upload, but all 3 files should remain on disk.
        storeOnDiskAndUpload(filesOnDisk: filesOnDisk, expectedUploadCount: 1)
        XCTWaiter().wait(for: [expectation(description: "process async events")], timeout: 1)
        XCTAssert(countFilesOnDisk() == filesOnDisk, "Confirm upload file exists")
    }

    func test4xxCode() {
        setupHttpResponseStub(statusCode: 400)
        storeOnDiskAndUpload(filesOnDisk: 3, expectedUploadCount: 3)
        XCTWaiter().wait(for: [expectation(description: "process async events")], timeout: 1)
        XCTAssert(countFilesOnDisk() == 0, "Confirm no more upload files")
    }

    func testTelemetryUpload() {
        setupHttpResponseStub()
        storeOnDiskAndUpload(filesOnDisk: 3, expectedUploadCount: 3)
        XCTWaiter().wait(for: [expectation(description: "process async events")], timeout: 1)
        XCTAssert(countFilesOnDisk() == 0, "Confirm no more upload files")
    }

    func testFileTimestamp() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let fileDate = TelemetryStorage.extractTimestampFromName(pingFile: URL(string: "a/b/c/foo-t-\(lastWeek.timeIntervalSince1970).json")!)!
        XCTAssert(fileDate.timeIntervalSince1970 > 0)
        XCTAssert(fabs(fileDate.timeIntervalSince1970 - lastWeek.timeIntervalSince1970) < 0.1 /* epsilon */)
        XCTAssert(TelemetryUtils.daysBetween(start: fileDate, end: Date()) == 7)
    }
}

