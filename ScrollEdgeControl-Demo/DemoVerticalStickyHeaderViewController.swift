import Foundation
import UIKit
import MondrianLayout
import StorybookUI
import StorybookKit
import StackScrollView
import ScrollEdgeControl
import CompositionKit

final class DemoVerticalStickyHeaderViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    let headerView = HeaderView()
      
    let stickyView = ScrollStickyVerticalHeaderView()
    
    view.backgroundColor = .white
    
    let scrollView = ScrollableContainerView()
    stickyView.setContent(headerView)
    
    let contentView = UIView()
    contentView.backgroundColor = .systemYellow.withAlphaComponent(0.8)
    
    contentView.mondrian.layout.height(300).activate()
    
    scrollView.setContent(contentView)
    scrollView.addSubview(stickyView)
    scrollView.alwaysBounceVertical = true
    
    Mondrian.buildSubviews(on: view) {
      ZStackBlock(alignment: .attach(.all)) {
        scrollView.viewBlock
      }
    }
    
  }

  private final class HeaderView: CodeBasedView, ScrollStickyContentType {
    
    private let label = UILabel()
    
    init() {
      
      super.init(frame: .null)
      
      backgroundColor = .systemBlue.withAlphaComponent(0.8)
//      mondrian.layout.height(100).activate()
      
      let button = UIButton(type: .system)
      button.setTitle("Update", for: .normal)
      button.addTarget(self, action: #selector(updateText), for: .primaryActionTriggered)
      
      label.numberOfLines = 0
      
      Mondrian.buildSubviews(on: self) {
        
        VStackBlock {
          StackingSpacer(minLength: 100)
          button
          label
            .viewBlock
            .padding(16)
        }
      }
    }
    
    @objc private func updateText() {
      label.text = BookGenerator.loremIpsum(length: [10, 50, 100].randomElement()!)
      requestUpdateSizing()
    }
    
  }
  
}
