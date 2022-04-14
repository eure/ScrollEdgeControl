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
    
//    let edgeControl = ScrollEdgeControl(edge: .top, configuration: .init(), activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black))
        
    let headerView = LongHeaderView()
      
    let stickyView = ScrollStickyVerticalHeaderView()
    
    view.backgroundColor = .white
    
    let scrollView = ScrollableContainerView()
    stickyView.setContent(headerView)
    
    let contentView = UIView()
    contentView.backgroundColor = .systemYellow.withAlphaComponent(0.8)
    contentView.mondrian.layout.height(1000).activate()
  
    Mondrian.buildSubviews(on: contentView) {
      VStackBlock {
        UIButton.make(title: "IsActive") {
          stickyView.setIsActive(!stickyView.isActive, animated: true)
        }
        
        UIButton.make(title: "Attaches SafeArea") {
          stickyView.configuration.attachesToSafeArea.toggle()
        }
        
        UIButton.make(title: "Short content") {
          stickyView.setContent(ShortHeaderView())
        }
        
        UIButton.make(title: "Long content") {
          stickyView.setContent(LongHeaderView())
        }
        
        StackingSpacer(minLength: 0)
      }
    }
    
    scrollView.setContent(contentView)
    scrollView.addSubview(stickyView)
//    scrollView.addSubview(edgeControl)
    scrollView.alwaysBounceVertical = true
    
    Mondrian.buildSubviews(on: view) {
      ZStackBlock(alignment: .attach(.all)) {
        scrollView.viewBlock
      }
    }
    
  }

  private final class LongHeaderView: CodeBasedView, ScrollStickyContentType {
    
    private let label = UILabel()
    
    init() {
      
      super.init(frame: .null)
      
      backgroundColor = .systemGray.withAlphaComponent(0.8)
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
            .padding(.vertical, 50)
        }
      }
    }
    
    @objc private func updateText() {
      label.text = BookGenerator.loremIpsum(length: [10, 50, 100].randomElement()!)
      requestUpdateSizing(animated: true)
    }
    
  }
  
  private final class ShortHeaderView: CodeBasedView, ScrollStickyContentType {
    
    private let label = UILabel()
    
    init() {
      
      super.init(frame: .null)
      
      backgroundColor = .systemPurple
      
      let label = UILabel()
      label.text = "Short"
   
      Mondrian.buildSubviews(on: self) {
        
        VStackBlock {
          StackingSpacer(minLength: 100)
          label
            .viewBlock
            .padding(32)
        }
      }
    }
    
  }
  
}
