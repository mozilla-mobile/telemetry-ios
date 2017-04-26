//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Telemetry

let configuration = Telemetry.default.configuration
configuration.appName = "TelemetryPlayground"
configuration.appVersion = "0.0.1"
configuration.updateChannel = "playground"
configuration.buildId = "1"

Telemetry.default.add(pingBuilderType: CorePingBuilder.self)

try! Telemetry.default.recordSessionStart()
sleep(1)
try! Telemetry.default.recordSessionEnd()

try! Telemetry.default.queue(pingType: CorePingBuilder.PingType)

DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { 
    let storage = TelemetryStorage(name: "MozTelemetry", configuration: Telemetry.default.configuration)
    storage.load(pingType: "core")
}

PlaygroundPage.current.needsIndefiniteExecution = true
