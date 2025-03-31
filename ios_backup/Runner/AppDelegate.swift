import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Request permissions for saving images to the gallery
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized, .limited:
          print("Photo library access granted.")
        case .denied, .restricted, .notDetermined:
          print("Photo library access denied or not determined.")
        @unknown default:
          print("Unknown photo library access status.")
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
