@testable import ScrollEdgeControl
import MondrianLayout
import UIKit
import CompositionKit

enum Components {

  static func makeScrollViewDebuggingView(scrollView: UIScrollView) -> UIView {

    let label = UILabel()
    label.numberOfLines = 0
    label.font = .systemFont(ofSize: 10)

    let handler = {

      label.text = """
        adjustedContentInset: \(scrollView.adjustedContentInset)
        contentInset: \(scrollView.contentInset)
        contentOffset: \(scrollView.contentOffset)

        local: \(scrollView._scrollEdgeControl_localContentInset)

        actualContentInset: \(scrollView.__original_contentInset)
        translation: \(scrollView.panGestureRecognizer.translation(in: nil).y)
        """
    }

    let token1 = scrollView.observe(\.contentInset) { _, change in
      handler()
    }

    let token2 = scrollView.observe(\.contentOffset) { _, change in
      handler()
    }

    return AnyView.init { _ in
      label
        .viewBlock
        .padding(4)
    }
    .setOnDeinit {
      withExtendedLifetime([token1, token2], {})
    }

  }

  static func makeDemoCell() -> UIView {
    let view = UIView()

    view.mondrian.layout
      .height(.exact(80, .defaultLow))
      .width(.exact(80, .defaultLow))
      .activate()

    view.backgroundColor = .init(white: 0.9, alpha: 1)
    view.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
    view.layer.borderWidth = 6
    view.layer.cornerRadius = 12
    if #available(iOS 13.0, *) {
      view.layer.cornerCurve = .continuous
    } else {
      // Fallback on earlier versions
    }

    return AnyView.init { _ in
      view
        .viewBlock
        .padding(4)
    }
  }

  static func makeSelectionView(title: String, onTap: @escaping () -> Void) -> UIView {

    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.onTap(onTap)

    return AnyView.init { view in
      VStackBlock {
        button
          .viewBlock
          .padding(10)
      }
    }
  }

  static func makeStepperView(
    title: String,
    onIncreased: @escaping () -> Void,
    onDecreased: @escaping () -> Void
  ) -> UIView {

    let titleLabel = UILabel()
    titleLabel.text = title

    let increaseButton = UIButton(type: .system)
    increaseButton.setTitle("+", for: .normal)
    increaseButton.onTap(onIncreased)

    let decreaseButton = UIButton(type: .system)
    decreaseButton.setTitle("-", for: .normal)
    decreaseButton.onTap(onDecreased)

    return AnyView.init { view in
      VStackBlock {
        titleLabel
        HStackBlock(spacing: 4) {
          increaseButton
            .viewBlock

          decreaseButton
            .viewBlock
        }
      }
      .padding(10)
    }
  }
}
