import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers
import CoreServices

class MainFlutterWindow: NSWindow {
  var methodChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Merge titlebar into content so native macOS traffic lights overlay Flutter UI seamlessly
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    setupMethodChannel(messenger: flutterViewController.engine.binaryMessenger)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  func notifyFileOpened(_ path: String) {
    methodChannel?.invokeMethod("onFileOpened", arguments: path)
  }

  private func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "com.example.markMyWords/system", binaryMessenger: messenger)
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "isRunningFromApplications":
        let path = Bundle.main.bundlePath
        let userApps = NSString(string: "~/Applications").expandingTildeInPath
        let isApps = path.hasPrefix("/Applications") || path.hasPrefix(userApps)
        result(isApps)

      case "moveToApplicationsFolder":
        self.moveToApplicationsFolder { success, error in
          if success {
            result(true)
          } else {
            result(FlutterError(code: "MOVE_FAILED", message: error ?? "Failed to move app to /Applications", details: nil))
          }
        }

      case "isDefaultMarkdownViewer":
        result(self.isDefaultMarkdownViewer())

      case "setDefaultMarkdownViewer":
        self.setDefaultMarkdownViewer { success, error in
          if success {
            result(true)
          } else {
            result(FlutterError(code: "SET_DEFAULT_FAILED", message: error ?? "Failed to set default viewer", details: nil))
          }
        }

      case "openApplicationsFolder":
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
        result(true)

      case "readFile":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Path argument is required", details: nil))
          return
        }
        let url = URL(fileURLWithPath: path)
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
          if isSecurityScoped {
            url.stopAccessingSecurityScopedResource()
          }
        }
        do {
          let content = try String(contentsOf: url, encoding: .utf8)
          result(content)
        } catch {
          do {
            let content = try String(contentsOf: url, encoding: .isoLatin1)
            result(content)
          } catch let readError {
            result(FlutterError(code: "READ_FAILED", message: readError.localizedDescription, details: nil))
          }
        }

      case "getInitialOpenedFile":
        result(AppDelegate.shared?.initialOpenedFile)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func isDefaultMarkdownViewer() -> Bool {
    let bundleId = Bundle.main.bundleIdentifier ?? "com.example.markMyWords"

    // 1. Check via LaunchServices role handler
    let types = ["net.daringfireball.markdown", "public.markdown"]
    for t in types {
      if let handler = LSCopyDefaultRoleHandlerForContentType(t as CFString, .all)?.takeRetainedValue() as String? {
        if handler.lowercased() == bundleId.lowercased() {
          return true
        }
      }
    }

    // 2. Check via NSWorkspace for a dummy .md file
    let tempDir = NSTemporaryDirectory()
    let testMdPath = (tempDir as NSString).appendingPathComponent(".markmywords_check.md")
    if !FileManager.default.fileExists(atPath: testMdPath) {
      FileManager.default.createFile(atPath: testMdPath, contents: Data(), attributes: nil)
    }
    let testMdUrl = URL(fileURLWithPath: testMdPath)
    if let appUrl = NSWorkspace.shared.urlForApplication(toOpen: testMdUrl),
       let defaultBundleId = Bundle(url: appUrl)?.bundleIdentifier {
      if defaultBundleId.lowercased() == bundleId.lowercased() {
        return true
      }
    }

    return false
  }

  private func setDefaultMarkdownViewer(completion: @escaping (Bool, String?) -> Void) {
    let bundleId = Bundle.main.bundleIdentifier ?? "com.example.markMyWords"
    let bundleUrl = Bundle.main.bundleURL

    let types = ["net.daringfireball.markdown", "public.markdown"]
    for t in types {
      _ = LSSetDefaultRoleHandlerForContentType(t as CFString, .all, bundleId as CFString)
    }

    if #available(macOS 12.0, *) {
      let extensions = ["md", "markdown", "mdown", "mkdn"]
      let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
      let group = DispatchGroup()
      var anyError: String?

      for type in contentTypes {
        group.enter()
        NSWorkspace.shared.setDefaultApplication(at: bundleUrl, toOpen: type) { error in
          if let error = error {
            anyError = error.localizedDescription
          }
          group.leave()
        }
      }

      group.notify(queue: .main) {
        completion(true, anyError)
      }
    } else {
      completion(true, nil)
    }
  }

  private func moveToApplicationsFolder(completion: @escaping (Bool, String?) -> Void) {
    let sourceUrl = Bundle.main.bundleURL
    let fileManager = FileManager.default
    var destUrl = URL(fileURLWithPath: "/Applications/\(sourceUrl.lastPathComponent)")

    // Fallback to ~/Applications if /Applications is not writable
    if !fileManager.isWritableFile(atPath: "/Applications") {
      let userApps = NSString(string: "~/Applications").expandingTildeInPath
      if !fileManager.fileExists(atPath: userApps) {
        try? fileManager.createDirectory(atPath: userApps, withIntermediateDirectories: true, attributes: nil)
      }
      destUrl = URL(fileURLWithPath: "\(userApps)/\(sourceUrl.lastPathComponent)")
    }

    do {
      if fileManager.fileExists(atPath: destUrl.path) {
        try fileManager.removeItem(at: destUrl)
      }
      try fileManager.copyItem(at: sourceUrl, to: destUrl)

      // Open the newly moved app from /Applications
      let config = NSWorkspace.OpenConfiguration()
      NSWorkspace.shared.openApplication(at: destUrl, configuration: config) { _, error in
        if let error = error {
          completion(false, error.localizedDescription)
        } else {
          DispatchQueue.main.async {
            NSApp.terminate(nil)
          }
        }
      }
    } catch {
      completion(false, error.localizedDescription)
    }
  }
}
