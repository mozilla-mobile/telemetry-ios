/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let background = "background"
    public static let foreground = "foreground"
}

class TelemetryEventObject {
    public static let app = "app"
}

class AppEvents {

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidEnterBackground(notification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    @objc func appWillResignActive(notification: NSNotification) {
        Telemetry.default.recordSessionEnd()
    }

    @objc func appDidEnterBackground(notification: NSNotification) {
        NSLog("~~~ background")

        Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)

    }

    @objc func appDidBecomeActive(notification: NSNotification) {
        Telemetry.default.recordSessionStart()

        // TODO: find a way to track this in-lib
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
    }
}



