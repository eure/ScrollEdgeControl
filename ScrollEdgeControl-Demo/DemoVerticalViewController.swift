import Foundation
import UIKit
import MondrianLayout
import StorybookUI
import StackScrollView
import ScrollEdgeControl

final class DemoVerticalViewController: UIViewController {

  struct Configuration {
    var startSideConfiguration: ScrollEdgeControl.Configuration?
    var endSideConfiguration: ScrollEdgeControl.Configuration?
  }

  let startScrollEdgeControl: ScrollEdgeControl?
  let endScrollEdgeControl: ScrollEdgeControl?

  private let scrollView = StackScrollView()
  private let menuView = StackScrollView()
  private let configuration: Configuration

  init(configuration: Configuration) {

    self.configuration = configuration

    if let configuration = configuration.startSideConfiguration {
      self.startScrollEdgeControl = ScrollEdgeControl(edge: .top, configuration: configuration, activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black))
    } else {
      self.startScrollEdgeControl = nil
    }

    if let configuration = configuration.endSideConfiguration {
      self.endScrollEdgeControl = ScrollEdgeControl(edge: .bottom, configuration: configuration, activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black))
    } else {
      self.endScrollEdgeControl = nil
    }

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
        menuView
      }
    }

    scrollView.mondrian.layout.width(.to(menuView).width).activate()

    menuView.append(views: [
      Components.makeScrollViewDebuggingView(scrollView: scrollView)
    ])

    if let control = startScrollEdgeControl {
      scrollView.addSubview(control)

      menuView.append(views: [
        Components.makeSelectionView(title: "Top: Activate", onTap: {
          control.setActivityState(.active, animated: true)
        }),
        Components.makeSelectionView(title: "Top: Deactivate", onTap: {
          control.setActivityState(.inactive, animated: true)
        })
      ])
    }

    if let control = endScrollEdgeControl {
      scrollView.addSubview(control)

      menuView.append(views: [
        Components.makeSelectionView(title: "Bottom: Activate", onTap: {
          control.setActivityState(.active, animated: true)
        }),
        Components.makeSelectionView(title: "Bottom: Deactivate", onTap: {
          control.setActivityState(.inactive, animated: true)
        })
      ])
    }

    menuView.append(views: [
      Components.makeStepperView(
        title: "Inset top",
        onIncreased: {
          scrollView.contentInset.top += 20
        },
        onDecreased: {
          scrollView.contentInset.top -= 20
        }),
      Components.makeStepperView(
        title: "Inset bottom",
        onIncreased: {
          scrollView.contentInset.bottom += 20
        },
        onDecreased: {
          scrollView.contentInset.bottom -= 20
        })
    ])


    scrollView.append(views: [
      Components.makeDemoCell(),
      Components.makeDemoCell(),
      Components.makeDemoCell(),
      Components.makeDemoCell(),
    ])

  }

}
