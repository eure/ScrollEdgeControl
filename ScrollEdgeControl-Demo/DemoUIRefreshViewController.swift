import Foundation
import UIKit
import MondrianLayout
import StorybookUI
import StackScrollView
import ScrollEdgeControl

final class DemoUIRefreshViewController: UIViewController {

  private let scrollView = StackScrollView()

  init() {

    super.init(nibName: nil, bundle: nil)

  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let scrollView = self.scrollView

    view.backgroundColor = .white

    view.mondrian.buildSubviews {
      HStackBlock {
        scrollView
      }
    }

    let cells = (0..<(20)).map { _ in
      Components.makeDemoCell()
    }

    scrollView.append(views: cells)

    let control = UIRefreshControl()

    scrollView.addSubview(control)

  }

}
