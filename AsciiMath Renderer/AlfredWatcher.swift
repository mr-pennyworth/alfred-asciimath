import AXSwift
import Cocoa
import Swindler
import PromiseKit
import CoreFoundation


class AlfredWatcher {
  var swindler: Swindler.State!
  var onDestroy: (() -> Void)!

  func start(onAlfredWindowDestroy: @escaping () -> Void) {
    self.onDestroy = onAlfredWindowDestroy
    guard AXSwift.checkIsProcessTrusted(prompt: true) else {
      NSLog("Not trusted as an AX process; please authorize and re-launch")
      NSApp.terminate(self)
      return
    }

    Swindler.initialize().done { state in
      self.swindler = state
      self.setupEventHandlers()
    }.catch { error in
      NSLog("Fatal error: failed to initialize Swindler: \(error)")
      NSApp.terminate(self)
    }
  }

  private func isAlfredWindow(window: Window) -> Bool {
    let bundle = window.application.bundleIdentifier ?? ""
    let title = window.title.value
    return (bundle == "com.runningwithcrayons.Alfred" && title == "Alfred")
  }

  private func setupEventHandlers() {
    swindler.on { (event: WindowDestroyedEvent) in
      if (self.isAlfredWindow(window: event.window)) {
        NSLog("Alfred window destroyed")
        self.onDestroy()
      }
    }
  }
}
