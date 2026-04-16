import Flutter
import MediaPipeTasksGenAI
import MediaPipeTasksText
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
