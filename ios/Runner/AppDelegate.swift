import UIKit
import Flutter
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Power Channel Setup
        let powerChannel = FlutterMethodChannel(
            name: "power_manager",
            binaryMessenger: controller.binaryMessenger
        )
        
        powerChannel.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "isLowPowerMode" {
                result(ProcessInfo.processInfo.isLowPowerModeEnabled)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        // Settings Channel Setup
        let settingsChannel = FlutterMethodChannel(
            name: "app_settings",
            binaryMessenger: controller.binaryMessenger
        )

        settingsChannel.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "openSettings" {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    result(true)
                } else {
                    result(false)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
