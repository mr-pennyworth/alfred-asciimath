import Alfred
import AppKit
import Carbon
import Foundation
import WebKit

// Floating webview based on: https://github.com/Qusic/Loaf

// Swift counterpart of return value of
// https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect
struct BoundingRect: Codable {
  let x: Double
  let y: Double
  let width: Double
  let height: Double
  let top: Double
  let bottom: Double
  let left: Double
  let right: Double

  func rect() -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
  }
}

class AppConfig {
  var screen: NSScreen = NSScreen.main!
  var alpha: CGFloat = 0.9

  lazy var size: NSSize = {
    let screenSize = screen.visibleFrame.size
    let width = 800
    let height = 200
    return NSSize(width: width, height: height)

  }()

  lazy var origin: NSPoint = {
    let screenFrame = screen.visibleFrame
    let x = Int(screenFrame.maxX - size.width) / 2
    let y = Int(screenFrame.maxY - size.height) / 2
    return NSPoint(x: x, y: y)
  }()

  lazy var url: URL = {
    Bundle.main.url(
      forResource: "index",
      withExtension: "html",
      subdirectory: "equation-renderer")!
  }()
}

class AppDelegate: NSObject, NSApplicationDelegate {
  let config: AppConfig
  let alfredWatcher: AlfredWatcher
  var math: String = ""

  lazy var window: NSWindow = {
    let window = NSWindow(
      contentRect: .zero,
      styleMask: [.borderless, .titled, .fullSizeContentView],
      backing: .buffered,
      defer: false,
      screen: config.screen)
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
    window.backgroundColor = NSColor.clear
    window.alphaValue = config.alpha

    // Gimmicks to get rounded corners
    // https://stackoverflow.com/a/27613308
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true

    return window
  }()

  lazy var webview: WKWebView = {
    let configuration = WKWebViewConfiguration()
    let webview = WKWebView(frame: .zero, configuration: configuration)
    return webview
  }()

  init(_ config: AppConfig) {
    self.config = config
    self.alfredWatcher = AlfredWatcher()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    window.contentView = webview
    window.setContentSize(config.size)
    window.setFrameOrigin(config.origin)

    webview.loadFileURL(config.url, allowingReadAccessTo: config.url)
    alfredWatcher.start(onAlfredWindowDestroy: {
      self.window.orderOut(self)
    })

    let asciiMathWorkflow = Alfred.workflow(id: "mr.pennyworth.asciimath")!
    Alfred.onItemSelect { selectedItem in
      if let workflowUID = selectedItem.workflowuid {
        if workflowUID == asciiMathWorkflow.uid {
          if let expr = selectedItem.uid {
            self.math = expr
            self.renderMath()
            return
          }
        }
      }
      self.window.orderOut(self)
    }
  }

  private func jsCallCode(funcName: String, arg: String) -> String {
    let escapedArg = arg.replacingOccurrences(of: "'", with: "\\'")
    return "\(funcName)('\(escapedArg)')";
  }

  private func renderMath() {
    NSLog("rendering math: \(math)")
    window.makeKeyAndOrderFront(self)
    webview.evaluateJavaScript(
      jsCallCode(funcName: "renderMath", arg: math),
      completionHandler: {(out, err) in
        // print(out!)
        // print(err!)
      })
  }

  private func copyLatex() {
    webview.evaluateJavaScript(
      jsCallCode(funcName: "getLatex", arg: math),
      completionHandler: {(out, err) in
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(out as! String, forType: .string)
        // print(out!)
        // print(err!)
      })
  }

  private func copyImage() {
    webview.evaluateJavaScript(
      "getImageBounds()",
      completionHandler: {(out, err) in
        do {
          let config = WKSnapshotConfiguration()
          config.rect = try JSONDecoder().decode(
            BoundingRect.self,
            from: (out as! String).data(using: .utf8)!
          ).rect()
          self.webview.takeSnapshot(with: config) { image, error in
            if let image = image {
              let pb = NSPasteboard.general
              pb.clearContents()
              pb.writeObjects([image])
            }
          }
        } catch let error {
          print(error)
        }

        // print(out!)
        // print(err!)
      })
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      switch url.host {
      case "copyImage": copyImage()
      case "copyLatex": copyLatex()
      case _: break
      }
    }
  }

}


autoreleasepool {
  let app = NSApplication.shared
  let config = AppConfig()
  let delegate = AppDelegate(config)
  app.setActivationPolicy(.accessory)
  app.delegate = delegate
  app.run()
}
