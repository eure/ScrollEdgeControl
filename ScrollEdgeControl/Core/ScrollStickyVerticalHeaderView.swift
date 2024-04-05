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

  public struct Configuration: Equatable {

    public var scrollsTogether: Bool
    public var attachesToSafeArea: Bool

    public init(scrollsTogether: Bool = true, attachesToSafeArea: Bool = false) {
      self.scrollsTogether = scrollsTogether
      self.attachesToSafeArea = attachesToSafeArea
    }
  }

  public struct ContentState: Equatable {
    public var contentOffset: CGPoint = .zero
    public var isActive: Bool = true
  }

  struct ComponentState: Equatable {
    var hasAttachedToScrollView = false
    var safeAreaInsets: UIEdgeInsets = .zero
    var contentOffset: CGPoint = .zero
    var isActive: Bool = true

    var configuration: Configuration
  }

  public var configuration: Configuration {
    get { componentState.configuration }
    set { componentState.configuration = newValue }
  }

  public var isActive: Bool {
    componentState.isActive
  }

  private var isInAnimating = false

  private var componentState: ComponentState {
    didSet {
      guard oldValue != componentState else {
        return
      }
      update(with: componentState, oldState: oldValue)
    }
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

  private var topConstraint: NSLayoutConstraint?

  private weak var targetScrollView: UIScrollView? = nil

  public init(configuration: Configuration = .init()) {

    self.componentState = .init(configuration: configuration)
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
    reloadState(animated: false)

    contentView.receive(state: contentState, oldState: nil)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()

    // sync frame
    // we don't use AutoLayout to prevent the content view from expanding inside.
    contentView?.frame = bounds
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

    // We cannot rely on the existence of self.superview to decide whether to setup scrollView,
    // because it did not exist yet on iOS 13.
    guard componentState.hasAttachedToScrollView == false else {
      // No need to setup scrollView.
      return
    }

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
      leftAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leftAnchor),
      rightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.rightAnchor),
      bottomAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor),
    ])

    // creates topConstraint
    reloadState(animated: false)
  }

  private func addObservation(scrollView: UIScrollView) {

    self.observations.forEach {
      $0.invalidate()
    }

    let newObservations: [NSKeyValueObservation]

    newObservations = [
      scrollView.observe(\.safeAreaInsets, options: [.initial, .new]) {
        [weak self] scrollView, _ in

        self?.componentState.safeAreaInsets = scrollView.safeAreaInsets
      },
      scrollView.observe(\.contentOffset, options: [.initial, .new]) {
        [weak self] scrollView, value in

        guard
          let self = self
        else {
          return
        }

        self.componentState.contentOffset = scrollView.contentOffset
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

        // check if already inserted to index 0.
        if let firstSubview = scrollView.subviews.first,
           firstSubview == self {
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

    if let targetScrollView = targetScrollView, state.configuration.attachesToSafeArea != oldState?.configuration.attachesToSafeArea {

      if state.configuration.attachesToSafeArea {
        topConstraint?.isActive = false
        topConstraint = topAnchor.constraint(equalTo: targetScrollView.safeAreaLayoutGuide.topAnchor)
        topConstraint?.isActive = true
      } else {
        topConstraint?.isActive = false
        topConstraint = topAnchor.constraint(equalTo: targetScrollView.frameLayoutGuide.topAnchor)
        topConstraint?.isActive = true
      }

      layoutIfNeeded()

    }

    if let targetScrollView = targetScrollView,
       let contentView = contentView,
       state.safeAreaInsets != oldState?.safeAreaInsets || state.isActive != oldState?.isActive || state.configuration != oldState?.configuration
    {

      let targetValue: CGFloat = {
        if state.isActive {

          let size = calculateFittingSize(view: contentView)

          if state.configuration.attachesToSafeArea {
            let targetValue = size.height
            return targetValue
          } else {
            let targetValue = size.height - state.safeAreaInsets.top
            return targetValue
          }

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

    if let topConstraint = topConstraint, state.contentOffset != oldState?.contentOffset || state.configuration != oldState?.configuration {
      if self.configuration.scrollsTogether {
        topConstraint.constant = min(0, -(state.contentOffset.y + (targetScrollView?.adjustedContentInset.top ?? 0)))
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
