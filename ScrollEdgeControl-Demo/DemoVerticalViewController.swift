//
//  DemoVerticalViewController.swift
//  ScrollEdgeControl-Demo
//
//  Created by Muukii on 2021/11/27.
//

import Foundation
import UIKit
import MondrianLayout
import StorybookUI
import StackScrollView
import ScrollEdgeControl

final class DemoVerticalViewController: UIViewController {

  struct Configuration {
    var topConfiguration: ScrollEdgeControl.Configuration?
    var bottomConfiguration: ScrollEdgeControl.Configuration?
  }

  private let scrollView = StackScrollView()
  private let menuView = StackScrollView()
  private let configuration: Configuration

  init(configuration: Configuration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

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

    if let configuration = configuration.topConfiguration {
      let control = ScrollEdgeControl(edge: .top, configuration: configuration, activityIndicatorView: DebuggingRefreshIndicatorView())
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

    if let configuration = configuration.bottomConfiguration {
      let control = ScrollEdgeControl(edge: .bottom, configuration: configuration, activityIndicatorView: DebuggingRefreshIndicatorView())
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


    scrollView.append(views: [
      Components.makeDemoCell(),
      Components.makeDemoCell(),
      Components.makeDemoCell(),
      Components.makeDemoCell(),
//      Components.makeSelectionView(title: "Hello", onTap: {
//
//      })
    ])

  }

}
