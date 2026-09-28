import Flutter
import AVFoundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureAudioSession()
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "hardsync/media_permissions",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "request",
              let options = call.arguments as? [String: Bool] else {
          result(FlutterMethodNotImplemented)
          return
        }

        let wantsMicrophone = options["microphone"] == true
        let wantsCamera = options["camera"] == true
        let group = DispatchGroup()
        let lock = NSLock()
        var allGranted = true
        func record(_ granted: Bool) {
          lock.lock()
          allGranted = allGranted && granted
          lock.unlock()
        }

        if wantsMicrophone {
          group.enter()
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            record(granted)
            group.leave()
          }
        }
        if wantsCamera {
          group.enter()
          AVCaptureDevice.requestAccess(for: .video) { granted in
            record(granted)
            group.leave()
          }
        }
        group.notify(queue: .main) {
          lock.lock()
          let allowed = allGranted
          lock.unlock()
          result(allowed)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Rehearsal calls run inside a WKWebView using getUserMedia for the mic.
  // Without an explicit category, iOS activates the audio session in a mode
  // that routes call audio to the earpiece receiver instead of the speaker,
  // so the AI counterpart's reply is effectively inaudible unless the device
  // is held up to your ear like a phone call.
  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
      )
      try session.setActive(true)
    } catch {
      print("Failed to configure AVAudioSession: \(error)")
    }
  }
}
