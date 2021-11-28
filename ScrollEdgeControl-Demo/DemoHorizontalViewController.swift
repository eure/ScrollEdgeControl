import Foundation
import MondrianLayout
import ScrollEdgeControl
import StackScrollView
import StorybookUI
import UIKit

final class DemoHorizontalViewController: UIViewController {

  struct Configuration {
    var numberOfElements: Int = 5
    var startSideConfiguration: ScrollEdgeControl.Configuration?
    var endSideConfiguration: ScrollEdgeControl.Configuration?
  }

  private let scrollView = StackScrollView(
    frame: .zero,
    collectionViewLayout: {
      let layout = UICollectionViewFlowLayout()
      layout.scrollDirection = .horizontal
      layout.minimumLineSpacing = 0
      layout.minimumInteritemSpacing = 0
      layout.sectionInset = .zero
      return layout
    }()
  )

  let startScrollEdgeControl: ScrollEdgeControl?
  let endScrollEdgeControl: ScrollEdgeControl?

  private let menuView = StackScrollView()
  private let configuration: Configuration

  init(
    configuration: Configuration
  ) {
    self.configuration = configuration

    if let configuration = configuration.startSideConfiguration {
      self.startScrollEdgeControl = ScrollEdgeControl(edge: .left, configuration: configuration, activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black))
    } else {
      self.startScrollEdgeControl = nil
    }

    if let configuration = configuration.endSideConfiguration {
      self.endScrollEdgeControl = ScrollEdgeControl(edge: .right, configuration: configuration, activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black))
    } else {
      self.endScrollEdgeControl = nil
    }

    super.init(nibName: nil, bundle: nil)
  }

  required init?(
    coder: NSCoder
  ) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let scrollView = self.scrollView

    view.backgroundColor = .white

    view.mondrian.buildSubviews {
      LayoutContainer(attachedSafeAreaEdges: .all) {

        VStackBlock {
          scrollView
            .viewBlock
            .height(120)
          menuView
        }
      }
    }

    menuView.append(views: [
      Components.makeScrollViewDebuggingView(scrollView: scrollView)
    ])

    if let control = startScrollEdgeControl {
      scrollView.addSubview(control)

      menuView.append(views: [
        Components.makeSelectionView(
          title: "Left: Activate",
          onTap: {
            control.setActivityState(.active, animated: true)
          }
        ),
        Components.makeSelectionView(
          title: "Left: Deactivate",
          onTap: {
            control.setActivityState(.inactive, animated: true)
          }
        ),
      ])
    }

    if let control = endScrollEdgeControl {
      scrollView.addSubview(control)

      menuView.append(views: [
        Components.makeSelectionView(
          title: "Right: Activate",
          onTap: {
            control.setActivityState(.active, animated: true)
          }
        ),
        Components.makeSelectionView(
          title: "Right: Deactivate",
          onTap: {
            control.setActivityState(.inactive, animated: true)
          }
        ),
      ])
    }

    menuView.append(views: [
      Components.makeStepperView(
        title: "Inset left",
        onIncreased: {
          scrollView.contentInset.left += 20
        },
        onDecreased: {
          scrollView.contentInset.left -= 20
        }
      ),
      Components.makeStepperView(
        title: "Inset right",
        onIncreased: {
          scrollView.contentInset.right += 20
        },
        onDecreased: {
          scrollView.contentInset.right -= 20
        }
      ),
    ])

    let cells = (0..<(configuration.numberOfElements)).map { _ in
      Components.makeDemoCell()
    }

    scrollView.append(views: cells)

  }
}
