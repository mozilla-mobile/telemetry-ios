import UIKit
import Telemetry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "AppInfo.displayName"
        telemetryConfig.userDefaultsSuiteName = "AppInfo.sharedContainerIdentifier"
        telemetryConfig.dataDirectory = .documentDirectory
        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadError(notification:)), name: Telemetry.notificationUploadError, object: nil)

        return true
    }

    @objc func uploadError(notification: NSNotification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        print("Upload error notification: \(error.localizedDescription)")
    }
}
