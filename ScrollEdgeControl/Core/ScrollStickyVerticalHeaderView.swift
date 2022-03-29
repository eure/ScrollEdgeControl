import UIKit

public protocol ScrollStickyContentType: UIView {

}

extension ScrollStickyContentType {

  public func requestUpdateSizing() {
    guard let target = superview as? ScrollStickyVerticalHeaderView else {
      return
    }

    target.updateContentInset()
  }
}

/**
 With: ``ScrollStickyContentType``
 */
public final class ScrollStickyVerticalHeaderView: UIView {

  public struct ComponentState: Equatable {
    var hasAttachedToScrollView = false
    var contentViewFrame: CGRect = .null
    var contentView: UIView?
  }

  public var componentState: ComponentState = .init()

  private var observations: [NSKeyValueObservation] = []

  private weak var targetScrollView: UIScrollView? = nil

  public init() {
    super.init(frame: .null)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setContent(_ contentView: UIView) {

    componentState.contentViewFrame = .null
    componentState.contentView = contentView

    subviews.forEach {
      $0.removeFromSuperview()
    }

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.rightAnchor.constraint(equalTo: rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    updateContentInset()

  }

  public override func didMoveToSuperview() {

    super.didMoveToSuperview()

    guard let superview = superview else {
      componentState.hasAttachedToScrollView = false
      return
    }

    guard let scrollView = superview as? UIScrollView else {
      assertionFailure()
      return
    }

    setupInScrollView(targetScrollView: scrollView)
  }

  private func setupInScrollView(targetScrollView scrollView: UIScrollView) {

    guard componentState.hasAttachedToScrollView == false else {
      assertionFailure("\(self) is alread atttached to scrollView\(targetScrollView as Any)")
      return
    }

    self.targetScrollView = scrollView

    componentState.hasAttachedToScrollView = true

    addObservation(scrollView: scrollView)

    self.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.topAnchor),
      leftAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leftAnchor),
      rightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.rightAnchor),
      bottomAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor),
    ])

  }

  private func addObservation(scrollView: UIScrollView) {
    
    self.observations.forEach {
      $0.invalidate()
    }

    let newObservations: [NSKeyValueObservation]

    newObservations = [
      scrollView.observe(\.safeAreaInsets, options: [.old, .new]) {
        [weak self] scrollView, _ in

        self?.updateContentInset()
      },
//      scrollView.observe(\.contentOffset, options: [.new]) {
//        [weak self] scrollView, value in
//
//        guard
//          let self = self
//        else {
//          return
//        }
//
//      },
    ]
    
    self.observations = newObservations
  }
 
  func updateContentInset() {

    guard let targetScrollView = targetScrollView else {
      return
    }
    
    /// for now, to get default adjustment content inset according to only safe-area-insets by setting 0 before setting new content inset.
    targetScrollView.contentInset.top = 0

    guard let contentView = componentState.contentView else {
      return
    }

    let adjustedContentInset = targetScrollView.adjustedContentInset

    let size = calculateFittingSize(view: contentView)

    targetScrollView.contentInset.top = size.height - adjustedContentInset.top
  }

  private func calculateFittingSize(view: UIView) -> CGSize {

    let size = view.systemLayoutSizeFitting(
      .init(width: self.bounds.width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )

    return size
  }
}
