import UIKit

@MainActor
private final class Proxy {
  
  static var key: Void?
  private weak var base: UIControl?
  
  init(_ base: UIControl) {
    self.base = base
  }
  
  var onTouchUpInside: (@MainActor () -> Void)? {
    didSet {
      base?.addTarget(
        self,
        action: #selector(touchUpInside(sender:)),
        for: .touchUpInside
      )
    }
  }
  
  var onValueChanged: (@MainActor () -> Void)? {
    didSet {
      base?.addTarget(
        self,
        action: #selector(valueChanged(sender:)),
        for: .valueChanged
      )
    }
  }
  
  @objc private dynamic func touchUpInside(sender: AnyObject) {
    onTouchUpInside?()
  }
  
  @objc private dynamic func valueChanged(sender: AnyObject) {
    onValueChanged?()
  }
}

extension UIControl {
  
  /// [Local extension]
  public func onTap(_ closure: @MainActor @escaping () -> Swift.Void) {
    proxy.onTouchUpInside = closure
  }
  
  public func onValueChanged(_ closure: @MainActor @escaping () -> Swift.Void) {
    proxy.onValueChanged = closure
  }
  
  private var proxy: Proxy {
    get {
      if let handler = objc_getAssociatedObject(self, &Proxy.key) as? Proxy {
        return handler
      } else {
        self.proxy = Proxy(self)
        return self.proxy
      }
    }
    set {
      objc_setAssociatedObject(self, &Proxy.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

extension UIButton {
  static func make(title: String, _ onTap: @escaping () -> Void) -> UIButton {
    let button = UIButton(frame: .zero)
    button.setTitle(title, for: .normal)
    button.onTap(onTap)
    return button
  }
}
