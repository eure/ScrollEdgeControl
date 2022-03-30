import Advance
import UIKit

public protocol ScrollStickyContentType: UIView {

  func receive(
    state: ScrollStickyVerticalHeaderView.ContentState,
    oldState: ScrollStickyVerticalHeaderView.ContentState?
  )
}

extension ScrollStickyContentType {

  public func requestUpdateSizing(animated: Bool) {
    guard let target = superview as? ScrollStickyVerticalHeaderView else {
      return
    }

    target.reloadState(animated: animated)
  }

  public func receive(
    state: ScrollStickyVerticalHeaderView.ContentState,
    oldState: ScrollStickyVerticalHeaderView.ContentState?
  ) {

  }
}

/// With: ``ScrollStickyContentType``
public final class ScrollStickyVerticalHeaderView: UIView {

  public struct ContentState: Equatable {
    public var contentOffset: CGPoint = .zero
    public var isActive: Bool = true
  }

  struct ComponentState: Equatable {
    var hasAttachedToScrollView = false
    var safeAreaInsets: UIEdgeInsets = .zero
    var isActive: Bool = true
  }

  private var isInAnimating = false
  private var componentState: ComponentState = .init() {
    didSet {
      guard oldValue != componentState else {
        return
      }
      update(with: componentState, oldState: oldValue)
    }
  }

  public var isActive: Bool {
    componentState.isActive
  }

  private var contentState: ContentState = .init() {
    didSet {
      guard oldValue != contentState else {
        return
      }
      contentView?.receive(state: contentState, oldState: oldValue)
    }
  }

  private var contentView: ScrollStickyContentType?
  private var observations: [NSKeyValueObservation] = []

  private var contentInsetTopDynamicAnimator: Animator<CGFloat>?

  private weak var targetScrollView: UIScrollView? = nil

  public init() {
    super.init(frame: .null)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setContent(_ contentView: ScrollStickyContentType) {

    self.contentView = contentView

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

    reloadState(animated: false)

    contentView.receive(state: contentState, oldState: nil)
  }

  public func setIsActive(_ isActive: Bool, animated: Bool) {

    if animated {
      isInAnimating = true
      componentState.isActive = isActive
      isInAnimating = false
    } else {
      componentState.isActive = isActive
    }

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

        self?.componentState.safeAreaInsets = scrollView.safeAreaInsets

      },
      scrollView.observe(\.contentOffset, options: [.new]) {
        [weak self] scrollView, value in

        guard
          let self = self
        else {
          return
        }

        self.contentState.contentOffset = scrollView.contentOffset
      },
      scrollView.layer.observe(\.sublayers, options: [.new]) {
        [weak self, weak scrollView] layer, value in
        
        guard
          let self = self,
          let scrollView = scrollView
        else {
          return
        }
        
        scrollView.insertSubview(self, at: 0)                        
      },

    ]

    self.observations = newObservations
  }

  internal func reloadState(animated: Bool) {

    if animated {
      isInAnimating = true
      update(with: componentState, oldState: nil)
      isInAnimating = false
    } else {
      update(with: componentState, oldState: nil)
    }
  }

  private func update(with state: ComponentState, oldState: ComponentState?) {

    assert(Thread.isMainThread)

    let animated = isInAnimating

    if state.isActive != oldState?.isActive {
      contentState.isActive = state.isActive
    }

    if let targetScrollView = targetScrollView,
      let contentView = contentView,
      state.safeAreaInsets != oldState?.safeAreaInsets || state.isActive != oldState?.isActive
    {

      let targetValue: CGFloat = {
        if state.isActive {

          let size = calculateFittingSize(view: contentView)
          let targetValue = size.height - state.safeAreaInsets.top
          return targetValue

        } else {

          return 0
        }
      }()

      if animated {

        contentInsetTopDynamicAnimator = Animator(initialValue: targetScrollView.contentInset.top)

        contentInsetTopDynamicAnimator!.onChange = { [weak self, weak targetScrollView] value in

          guard let self = self, let targetScrollView = targetScrollView else {
            return
          }

          guard targetScrollView.isTracking == false else {
            self.contentInsetTopDynamicAnimator?.cancelRunningAnimation()
            self.contentInsetTopDynamicAnimator = nil
            targetScrollView.contentInset.top = targetValue
            return
          }

          targetScrollView.contentInset.top = value

        }

        contentInsetTopDynamicAnimator!.simulate(
          using: SpringFunction(
            target: targetValue,
            tension: 1200,
            damping: 120
          )
        )

      } else {

        contentInsetTopDynamicAnimator?.cancelRunningAnimation()
        contentInsetTopDynamicAnimator = nil

        targetScrollView.contentInset.top = targetValue

      }
    }

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
