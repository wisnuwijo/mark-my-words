import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static var shared: AppDelegate? {
    return NSApp.delegate as? AppDelegate
  }

  var initialOpenedFile: String?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // If launched via command line or LaunchServices argument (e.g. open -a MarkMyWord file.md)
    if initialOpenedFile == nil && CommandLine.arguments.count > 1 {
      let candidate = CommandLine.arguments[1]
      if !candidate.starts(with: "-") {
        initialOpenedFile = candidate
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    handleOpenedFiles([filename])
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    handleOpenedFiles(filenames)
  }

  @available(macOS 10.13, *)
  override func application(_ application: NSApplication, open urls: [URL]) {
    let paths = urls.map { $0.path }
    handleOpenedFiles(paths)
  }

  private func handleOpenedFiles(_ filenames: [String]) {
    guard let firstFile = filenames.first, !firstFile.isEmpty else { return }
    initialOpenedFile = firstFile

    let window = (self.mainFlutterWindow as? MainFlutterWindow)
      ?? (NSApp.windows.first(where: { $0 is MainFlutterWindow }) as? MainFlutterWindow)
    window?.notifyFileOpened(firstFile)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
