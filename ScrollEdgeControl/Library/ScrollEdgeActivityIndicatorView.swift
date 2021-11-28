import Foundation
import UIKit

public final class ScrollEdgeActivityIndicatorView: UIView,
  ScrollEdgeActivityIndicatorViewType
{

  private let fractionIndicator: DonutsIndicatorFractionView
  private let donutsIndicator: DonutsIndicatorView

  public init(
    color: DonutsIndicatorView.Color
  ) {

    fractionIndicator = .init(size: .medium, color: color)
    donutsIndicator = .init(size: .medium, color: color)

    super.init(frame: .zero)

    addSubview(fractionIndicator)
    addSubview(donutsIndicator)

  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()

    /**
     [Workaround for using Texture]
     It should be laid out manually since the ASCollectionNode won't display cells initially in a horizontal scroll by using AutoLayout in the ASCollectionView.
     */
    fractionIndicator.center = bounds.center
    donutsIndicator.center = bounds.center
    fractionIndicator.bounds.size = fractionIndicator.intrinsicContentSize
    donutsIndicator.bounds.size = donutsIndicator.intrinsicContentSize

  }

  public func setColor(_ color: DonutsIndicatorView.Color) {
    fractionIndicator.setColor(color)
    donutsIndicator.setColor(color)
  }

  public func update(withState state: ScrollEdgeControl.ActivatingState) {

    switch state {
    case .triggering(let progress):

      donutsIndicator.alpha = 0
      donutsIndicator.stopAnimating()

      if progress > 0 {

        fractionIndicator.alpha = 1
        fractionIndicator.setProgress(progress)

      } else {

        if fractionIndicator.alpha != 0 {

          fractionIndicator.alpha = 0

          let t = CATransition()
          t.duration = 0.2
          fractionIndicator.layer.add(t, forKey: "fade")
        }
      }

    case .active:

      donutsIndicator.alpha = 1
      donutsIndicator.startAnimating()

      fractionIndicator.alpha = 0

      let t = CATransition()
      t.duration = 0.2

      layer.add(t, forKey: "fade")

    case .completed:
      
      donutsIndicator.stopAnimating()
      fractionIndicator.setProgress(0)
      fractionIndicator.alpha = 0

    }

  }

}

extension ScrollEdgeControl {

  public static func donutsIndicator(
    edge: ScrollEdgeControl.Edge,
    configuration: ScrollEdgeControl.Configuration,
    color: DonutsIndicatorView.Color = .black
  ) -> Self {

    let instance = Self.init(
      edge: edge,
      configuration: configuration,
      activityIndicatorView: ScrollEdgeActivityIndicatorView(color: color)
    )

    return instance
  }
}

extension CGRect {
  // MARK: Public

  public var center: CGPoint {
    return CGPoint(x: self.midX, y: self.midY)
  }
}
