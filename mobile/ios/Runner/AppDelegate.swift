import Flutter
// MediaPipeTasksText is not resolved by the current CocoaPods spec set.
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let sharedImportBridgeHandler = SharedImportBridgeHandler()
  private var sharedImportChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as? FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.curator.curator_mobile/litert_lm",
      binaryMessenger: controller!.binaryMessenger
    )
    channel.setMethodCallHandler(LiteRtLlmBridgeHandler().handle)

    sharedImportChannel = FlutterMethodChannel(
      name: "com.curator.curator_mobile/shared_imports",
      binaryMessenger: controller!.binaryMessenger
    )
    sharedImportChannel?.setMethodCallHandler(sharedImportBridgeHandler.handle)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    sharedImportChannel?.invokeMethod("appDidResume", arguments: nil)
  }
}
