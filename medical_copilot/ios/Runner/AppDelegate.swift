import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "medical_copilot/audio_native",
                                       binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setGain":
        // iOS gain is managed by the audio session; the hook is here for
        // extension but is a no-op in this scaffold.
        result(nil)
      case "startForegroundService", "stopForegroundService":
        // Not applicable on iOS; ignore.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord,
                              mode: .default,
                              options: [.allowBluetooth, .defaultToSpeaker])
      try session.setActive(true)
    } catch {
      NSLog("Failed to configure AVAudioSession: \(error)")
    }
  }
}
