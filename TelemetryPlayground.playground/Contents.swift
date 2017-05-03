//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Telemetry

let configuration = Telemetry.default.configuration
configuration.appName = "Focus"
configuration.appVersion = "3.3"
configuration.updateChannel = "debug"
configuration.buildId = "1"

Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)

try! Telemetry.default.recordSessionStart()
sleep(1)
try! Telemetry.default.recordSessionEnd()

try! Telemetry.default.record(event: TelemetryEvent(category: "action", method: "type_url", object: "search_bar", value: nil))
try! Telemetry.default.record(event: TelemetryEvent(category: "action", method: "type_url", object: "search_bar", value: nil))
try! Telemetry.default.record(event: TelemetryEvent(category: "action", method: "type_url", object: "search_bar", value: nil))

try! Telemetry.default.queue(pingType: CorePingBuilder.PingType)
try! Telemetry.default.queue(pingType: FocusEventPingBuilder.PingType)

//Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)
Telemetry.default.scheduleUpload(pingType: FocusEventPingBuilder.PingType)

//DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//    let storage = TelemetryStorage(name: "MozTelemetry", configuration: Telemetry.default.configuration)
//    
//    print("Core Pings")
//    while let ping = storage.dequeue(pingType: CorePingBuilder.PingType) {
//        print(String(data: ping.measurementsJSON()!, encoding: .utf8)!)
//    }
//    
//    print("FocusEvent Pings")
//    while let ping = storage.dequeue(pingType: FocusEventPingBuilder.PingType) {
//        print(String(data: ping.measurementsJSON()!, encoding: .utf8)!)
//    }
//}

PlaygroundPage.current.needsIndefiniteExecution = true
