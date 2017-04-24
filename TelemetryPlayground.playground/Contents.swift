//: Playground - noun: a place where people can play

import UIKit
import Telemetry

let configuration = Telemetry.default.configuration
configuration.appName = "TelemetryPlayground"
configuration.appVersion = "0.0.1"
configuration.updateChannel = "playground"
configuration.buildId = "1"

Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
