import Alfred

class AlfredWatcher {
  var onDestroy: (() -> Void)!

  func start(onAlfredWindowDestroy: @escaping () -> Void) {
    Alfred.onHide(callback: onAlfredWindowDestroy)
  }
}
