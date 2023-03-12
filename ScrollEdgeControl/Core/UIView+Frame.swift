import UIKit

extension UIView {

  func resetCenter() {

    let center = CGPoint(x: bounds.midX, y: bounds.midY)

    guard self.center != center else { return }
    self.center = center
  }

}
