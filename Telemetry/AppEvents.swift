/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class AppEvents {
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidEnterBackground(notification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    @objc func appWillResignActive(notification: NSNotification) {
        if Telemetry.default.hasPingType(CorePingBuilder.PingType) {
            Telemetry.default.recordSessionEnd()
        }
    }

    @objc func appDidEnterBackground(notification: NSNotification) {
        Telemetry.default.forEachPingType { pingType in
            Telemetry.default.queue(pingType: pingType)
            Telemetry.default.scheduleUpload(pingType: pingType)
        }
    }

    @objc func appDidBecomeActive(notification: NSNotification) {
        if Telemetry.default.hasPingType(CorePingBuilder.PingType) {
            Telemetry.default.recordSessionStart()
        }
    }
}



