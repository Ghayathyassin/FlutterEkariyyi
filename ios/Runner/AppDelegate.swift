import Flutter
import UIKit
import QuickLook

// iOS counterpart of android/.../MainActivity.kt: the `lrc/downloads` MethodChannel
// used to open the receipt / title-register PDF that the payment-completion and
// PendingPayment endpoints return as base64 (see lib/widgets/receipt_dialog.dart).
//
// Contract is identical to the Android side so the Dart code needs no changes:
//   channel  "lrc/downloads"
//   method   "openPdf"
//   args     { bytes: Uint8List, fileName: String }
//   result   true, or FlutterError("NO_BYTES" | "OPEN_FAILED"), else notImplemented
//
// Android writes to cacheDir and hands out a FileProvider content:// uri; iOS has
// no such requirement — the file goes to the app's own temporary directory and is
// shown with QLPreviewController, which is sandboxed to this app already.
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  // QLPreviewController holds its dataSource WEAKLY, so it must be retained here
  // or the preview opens blank.
  private var pdfPreviewSource: PdfPreviewSource?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "lrc/downloads",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "openPdf" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        guard let data = (args?["bytes"] as? FlutterStandardTypedData)?.data,
              !data.isEmpty else {
          result(FlutterError(code: "NO_BYTES", message: "No bytes provided", details: nil))
          return
        }
        let fileName = (args?["fileName"] as? String) ?? "document.pdf"
        do {
          try self?.openPdf(data: data, fileName: fileName, from: controller)
          result(true)
        } catch {
          result(FlutterError(code: "OPEN_FAILED",
                              message: error.localizedDescription,
                              details: nil))
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func openPdf(data: Data, fileName: String, from controller: UIViewController) throws {
    // Strip any path components a backend-supplied name might carry.
    let trimmed = (fileName as NSString).lastPathComponent
    let safeName = trimmed.isEmpty ? "document.pdf" : trimmed
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
    try data.write(to: url, options: .atomic)

    let source = PdfPreviewSource(url: url)
    pdfPreviewSource = source

    let preview = QLPreviewController()
    preview.dataSource = source

    // The receipt dialog is itself a presented modal, so present from the
    // top-most controller rather than the Flutter one.
    var presenter: UIViewController = controller
    while let presented = presenter.presentedViewController {
      presenter = presented
    }
    presenter.present(preview, animated: true)
  }
}

private final class PdfPreviewSource: NSObject, QLPreviewControllerDataSource {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(_ controller: QLPreviewController,
                         previewItemAt index: Int) -> QLPreviewItem {
    return url as NSURL
  }
}
