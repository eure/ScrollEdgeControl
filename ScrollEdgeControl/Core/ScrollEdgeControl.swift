
import Advance
import UIKit
import os.log

/// A protocol that indicates the view can be displayed on ScrollEdgeControl.
public protocol ScrollEdgeActivityIndicatorViewType: UIView {

  func update(withState state: ScrollEdgeControl.ActivatingState)
}

/// A customizable control that attaches at edges of the scrollview.
///
/// - Pulling to refresh (interchangeable with UIRefreshControl)
/// - Can be attached in multiple edges (top, left, right, bottom)
public final class ScrollEdgeControl: UIControl {

  public struct Handlers {
    public var onDidActivate: (ScrollEdgeControl) -> Void = { _ in }
  }

  /**
   Configurations for ScrollEdgeControl
   */
  public struct Configuration {

    /**
     Options how lays out ScrollEdgeControl in ScrollView
     */
    public enum LayoutMode {
      /**
       Fixes the position to the specified edge with respecting content-inset.
       */
      case fixesToEdge

      /**
       Scrolls itself according to the content
       */
      case scrollingAlongContent
    }

    public enum ZLayoutMode {
      /// front of content
      case front
      /// back of content
      case back
    }

    public enum PullToActivateMode {
      case enabled(addsInset: Bool)
      case disabled
    }

    public var layoutMode: LayoutMode = .fixesToEdge
    public var zLayoutMode: ZLayoutMode = .back

    public var pullToActivateMode: PullToActivateMode = .enabled(addsInset: true)

    /// A length to the target edge.
    /// You might use this when you need to lay it out away from the edge.
    public var marginToEdge: CGFloat = 0

    public init() {}

    public init(
      _ modify: (inout Self) -> Void
    ) {
      var instance = Self.init()
      modify(&instance)
      self = instance
    }

  }

  public enum ActivatingState: Equatable {
    case triggering(progress: CGFloat)
    case active
    case completed
  }

  /**
   A representation of the edge
   */
  public enum Edge: Equatable {
    case top
    case bottom
    case right
    case left

    enum Direction: Equatable {
      case vertical
      case horizontal
    }

    var direction: Direction {
      switch self {
      case .top, .bottom: return .vertical
      case .left, .right: return .horizontal
      }
    }
  }

  private enum DirectionalEdge {
    case start
    case end
  }

  public struct ComponentState: Equatable {
    var hasAttachedToScrollView = false
    var isIdlingToPull: Bool = true
    public fileprivate(set) var activityState: ActivityState = .inactive
  }

  public struct ActivityState: Equatable {
    public var isActive: Bool

    /**
     A Boolean value that indicates whether adding content inset to the target scroll view to make activity indicator visible.
     */
    public var addsInset: Bool

    public init(
      isActive: Bool,
      addsInset: Bool
    ) {
      self.isActive = isActive
      self.addsInset = addsInset
    }

    public static var active: Self {
      return .init(isActive: true, addsInset: true)
    }

    public static var inactive: Self {
      return .init(isActive: false, addsInset: false)
    }

    public static func active(addsInset: Bool) -> Self {
      return .init(isActive: true, addsInset: addsInset)
    }

    public static func inactive(addsInset: Bool) -> Self {
      return .init(isActive: false, addsInset: addsInset)
    }

  }

  fileprivate enum Log {

    private static let log: OSLog = {
      #if SCROLLEDGECONTROL_LOG_ENABLED
      return OSLog.init(subsystem: "ScrollEdgeControl", category: "ScrollEdgeControl")
      #else
      return .disabled
      #endif
    }()

    static func debug(_ object: Any...) {
      os_log(.debug, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
    }

  }

  private enum Constants {

    static let refreshIndicatorLengthAlongScrollDirection: CGFloat = 50
    static let rubberBandingLengthToTriggerRefreshing: CGFloat =
      refreshIndicatorLengthAlongScrollDirection * 1.6
    static let refreshAnimationAutoScrollMargin: CGFloat = 10
  }

  public var handlers: Handlers = .init()

  private let targetEdge: Edge

  public var componentState: ComponentState = .init()

  public var configuration: Configuration {
    didSet {
      layoutSelfInScrollView()
    }
  }

  public var isActive: Bool {
    componentState.activityState.isActive
  }

  private weak var targetScrollView: UIScrollView? = nil
  private var contentInsetDynamicAnimator: Advance.Animator<CGFloat>?
  private var activityIndicatorView: ScrollEdgeActivityIndicatorViewType?
  private var offsetObservation: NSKeyValueObservation?
  private var insetObservation: NSKeyValueObservation?
  private let feedbackGenerator: UIImpactFeedbackGenerator = .init(style: .light)
  private var scrollController: ScrollController?

  private var refreshingState: ActivatingState = .completed {
    didSet {
      activityIndicatorView?.update(withState: refreshingState)
    }
  }

  public init(
    edge: Edge,
    configuration: Configuration,
    activityIndicatorView: ScrollEdgeActivityIndicatorViewType
  ) {

    self.targetEdge = edge
    self.configuration = configuration

    super.init(frame: .zero)

    isUserInteractionEnabled = false

    setActivityIndicatorView(activityIndicatorView)
  }

  @available(*, unavailable)
  public required init?(
    coder: NSCoder
  ) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {

  }

  /**
   Sets Activity State - animatable
   */
  public func setActivityState(_ state: ActivityState, animated: Bool) {

    let previous = componentState.activityState
    componentState.activityState = state

    switch state.isActive {
    case true:

      guard !previous.isActive else {
        break
      }

      refreshingState = .active

    case false:

      guard previous.isActive == true else {
        break
      }

      refreshingState = .completed

    }

    switch state.addsInset {
    case true:
      addLocalContentInsetInTargetScrollView(animated: animated)
    case false:
      removeLocalContentInsetInTargetScrollView(animated: animated)
    }
  }


  public func setActivityIndicatorView(_ view: ScrollEdgeActivityIndicatorViewType) {

    if let current = activityIndicatorView {
      current.removeFromSuperview()
    }

    activityIndicatorView = view

    addSubview(view)
    view.frame = bounds
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

    layoutSelfInScrollView()

    activityIndicatorView?.update(withState: refreshingState)

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

    _ = UIScrollView.swizzle

    scrollView._userContentInset = scrollView.__original_contentInset

    feedbackGenerator.prepare()

    setupInScrollView(targetScrollView: scrollView)
  }

  private func setupInScrollView(targetScrollView scrollView: UIScrollView) {

    guard componentState.hasAttachedToScrollView == false else {
      assertionFailure("\(self) is alread atttached to scrollView\(targetScrollView as Any)")
      return
    }

    self.targetScrollView = scrollView
    self.scrollController = .init(scrollView: scrollView)

    componentState.hasAttachedToScrollView = true

    addOffsetObservation(scrollView: scrollView)
    addInsetObservation(scrollView: scrollView)

    layoutSelfInScrollView()

    setActivityState(componentState.activityState, animated: false)
  }

  private func addLocalContentInsetInTargetScrollView(animated: Bool) {

    guard let scrollView = self.targetScrollView else { return }

    let targetHeight = Constants.refreshIndicatorLengthAlongScrollDirection

    guard scrollView._scrollEdgeControl_localContentInset[edge: targetEdge] != targetHeight else {
      return
    }

    Log.debug("add local content inset")

    contentInsetDynamicAnimator?.cancelRunningAnimation()

    if animated {

      contentInsetDynamicAnimator = Animator(
        initialValue: scrollView._scrollEdgeControl_localContentInset[edge: self.targetEdge]
      )

      contentInsetDynamicAnimator!.onChange = { [weak self, weak scrollView] value in

        guard
          let self = self,
          let scrollView = scrollView
        else {
          return
        }

        let userContentInset = scrollView._userContentInset

        /// reads every frame to support multiple components.
        let capturedAdjustedContentInset = scrollView.adjustedContentInset.subtracting(
          scrollView._scrollEdgeControl_localContentInset
        )

        guard scrollView.isTracking == false else {

          /**
           stop animation by interruption
           */

          self.contentInsetDynamicAnimator?.cancelRunningAnimation()

          scrollView._scrollEdgeControl_localContentInset[edge: self.targetEdge] = targetHeight
          scrollView.__original_contentInset[edge: self.targetEdge] =
            userContentInset[edge: self.targetEdge] + targetHeight

          return
        }

        scrollView._scrollEdgeControl_localContentInset[edge: self.targetEdge] = value
        scrollView.__original_contentInset[edge: self.targetEdge] =
          userContentInset[edge: self.targetEdge] + value

        switch self.targetEdge {
        case .top:
          if scrollView.contentOffset.y < -targetHeight + Constants.refreshAnimationAutoScrollMargin
          {
            scrollView.contentOffset.y = -(capturedAdjustedContentInset.top + value)
          }
        case .bottom:

          if Self.isScrollableVertically(scrollView: scrollView),
            scrollView.contentOffset.y
              > (Self.maximumContentOffset(of: scrollView).y
                - Constants.refreshAnimationAutoScrollMargin)
          {
            scrollView.contentOffset.y = (Self.maximumContentOffset(of: scrollView).y + value)
          }
        case .left:
          if scrollView.contentOffset.x < -targetHeight + Constants.refreshAnimationAutoScrollMargin
          {
            scrollView.contentOffset.x = -(capturedAdjustedContentInset.left + value)
          }
        case .right:
          if Self.isScrollableHorizontally(scrollView: scrollView),
            scrollView.contentOffset.x
              > (Self.maximumContentOffset(of: scrollView).x
                - Constants.refreshAnimationAutoScrollMargin)
          {
            scrollView.contentOffset.x = (Self.maximumContentOffset(of: scrollView).x + value)
          }
        }
      }

      contentInsetDynamicAnimator!.simulate(
        using: SpringFunction(
          target: Constants.refreshIndicatorLengthAlongScrollDirection,
          tension: 1200,
          damping: 120
        )
      )

    } else {

      scrollView._scrollEdgeControl_localContentInset[edge: targetEdge] = targetHeight
      scrollView.__original_contentInset[edge: targetEdge] +=
        scrollView._userContentInset[edge: targetEdge] + targetHeight

    }
  }

  private func removeLocalContentInsetInTargetScrollView(animated: Bool) {

    guard let scrollView = self.targetScrollView else { return }

    guard scrollView._scrollEdgeControl_localContentInset[edge: targetEdge] != 0 else {
      return
    }

    Log.debug("Start : remove local content inset")

    contentInsetDynamicAnimator?.cancelRunningAnimation()

    if animated {

      contentInsetDynamicAnimator = Animator(
        initialValue: Constants.refreshIndicatorLengthAlongScrollDirection
      )

      let targetValue: CGFloat = 0

      contentInsetDynamicAnimator!.onChange = { [weak self, weak scrollView] value in

        guard let self = self else { return }
        guard let scrollView = scrollView else { return }

        if value == targetValue {
          Log.debug("Complete : remove local content inset")
        }

        let userContentInset = scrollView._userContentInset

        guard scrollView.isTracking == false else {

          self.contentInsetDynamicAnimator?.cancelRunningAnimation()

          let contentOffset = scrollView.contentOffset

          self.removeOffsetObservation()

          do {
            scrollView._scrollEdgeControl_localContentInset[edge: self.targetEdge] = 0
            scrollView.__original_contentInset[edge: self.targetEdge] =
              userContentInset[edge: self.targetEdge]

            /// to keep current tracking content offset.
            scrollView.contentOffset = contentOffset
          }

          self.addOffsetObservation(scrollView: scrollView)

          return
        }

        scrollView._scrollEdgeControl_localContentInset[edge: self.targetEdge] = value
        scrollView.__original_contentInset[edge: self.targetEdge] =
          userContentInset[edge: self.targetEdge] + (value)

      }

      contentInsetDynamicAnimator!.simulate(
        using: SpringFunction(
          target: targetValue,
          tension: 1200,
          damping: 120
        )
      )
    } else {

      scrollView._scrollEdgeControl_localContentInset[edge: targetEdge] = 0
      scrollView.__original_contentInset[edge: targetEdge] =
        scrollView._userContentInset[edge: targetEdge]

    }
  }

  private func _pullToRefresh_beginRefreshing() {

    guard componentState.activityState.isActive == false,
      let scrollView = targetScrollView
    else {
      return
    }

    componentState.activityState.isActive = true
    componentState.isIdlingToPull = false

    activityIndicatorView?.update(withState: .active)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      guard let self = self else { return }
      self.sendActions(for: .valueChanged)
      self.handlers.onDidActivate(self)
    }

    feedbackGenerator.impactOccurred()

    guard case .enabled(true) = configuration.pullToActivateMode else {
      return
    }

    removeOffsetObservation()
    defer {
      addOffsetObservation(scrollView: scrollView)
    }

    scrollView._scrollEdgeControl_localContentInset[edge: targetEdge] =
      Constants.refreshIndicatorLengthAlongScrollDirection

    /// update contentInset internally with scroll locking
    do {
      /// prevents glitches
      scrollController!.lockScrolling()
      scrollView.__original_contentInset[edge: targetEdge] +=
        Constants.refreshIndicatorLengthAlongScrollDirection
      scrollController!.unlockScrolling()
    }

    /// prevents jumping (still jumping slightly)
    var translation = scrollView.panGestureRecognizer.translation(in: nil)
    switch targetEdge {
    case .top:
      translation.y -= Constants.refreshIndicatorLengthAlongScrollDirection + 10
    case .bottom:
      translation.y += Constants.refreshIndicatorLengthAlongScrollDirection + 10
    case .left:
      translation.x -= Constants.refreshIndicatorLengthAlongScrollDirection + 45
    case .right:
      translation.x += Constants.refreshIndicatorLengthAlongScrollDirection + 45
    }
    /** this constant is needed to keep the current content offset */
    scrollView.panGestureRecognizer.setTranslation(translation, in: nil)

  }

  private func layoutSelfInScrollView() {

    func setFrame(_ frame: CGRect) {
      guard self.frame != frame else {
        return
      }
      self.frame = frame
    }

    func setZPosition(_ position: CGFloat) {
      guard layer.zPosition != position else { return }
      layer.zPosition = position
    }

    guard let scrollView = targetScrollView else {
      return
    }

    switch configuration.zLayoutMode {
    case .front:
      setZPosition(1)
    case .back:
      setZPosition(-1)
    }

    let length: CGFloat

    switch configuration.layoutMode {
    case .fixesToEdge:
      length = scrollView.distance(from: targetEdge) - configuration.marginToEdge
    case .scrollingAlongContent:
      length = -configuration.marginToEdge
    }

    let sizeForVertical = CGSize.init(
      width: scrollView.bounds.width,
      height: Constants.refreshIndicatorLengthAlongScrollDirection
    )

    let sizeForHorizontal = CGSize.init(
      width: Constants.refreshIndicatorLengthAlongScrollDirection,
      height: scrollView.bounds.height
    )

    switch targetEdge {
    case .top:

      let frame = CGRect(
        origin: .init(
          x: 0,
          y: -scrollView._scrollEdgeControl_localContentInset.top - length
        ),
        size: sizeForVertical
      )

      setFrame(frame)

    case .bottom:

      let frame = CGRect(
        origin: .init(
          x: 0,
          y: scrollView.contentSize.height - Constants.refreshIndicatorLengthAlongScrollDirection
            + length + scrollView._scrollEdgeControl_localContentInset.bottom
        ),
        size: sizeForVertical
      )

      setFrame(frame)

    case .left:

      let frame = CGRect(
        origin: .init(
          x: -scrollView._scrollEdgeControl_localContentInset.left - length,
          y: 0
        ),
        size: sizeForHorizontal
      )

      setFrame(frame)

    case .right:

      let frame = CGRect(
        origin: .init(
          x: scrollView.contentSize.width - Constants.refreshIndicatorLengthAlongScrollDirection
            + length + scrollView._scrollEdgeControl_localContentInset.right,
          y: 0
        ),
        size: sizeForHorizontal
      )

      setFrame(frame)

    }

  }

  private func addInsetObservation(scrollView: UIScrollView) {

    insetObservation = scrollView.observe(\.contentInset, options: [.old, .new]) {
      [weak self] scrollView, _ in

      guard let self = self else { return }
      self.layoutSelfInScrollView()

    }
  }

  /// https://github.com/gontovnik/DGElasticPullToRefresh/blob/master/DGElasticPullToRefresh/DGElasticPullToRefreshView.swift
  private func addOffsetObservation(scrollView: UIScrollView) {

    offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) {
      [weak self, targetEdge] scrollView, value in

      guard
        let self = self
      else {
        return
      }

      self.layoutSelfInScrollView()

      if scrollView.rubberBandingLength(from: targetEdge) == 0 {
        self.componentState.isIdlingToPull = true
      }

      if case .enabled = self.configuration.pullToActivateMode {

        let remainsTriggering: Bool = {
          if case .triggering(let p) = self.refreshingState {
            return p > 0
          } else {
            return false
          }
        }()

        if self.componentState.isIdlingToPull && (scrollView.isTracking || remainsTriggering) {

          if self.componentState.activityState.isActive == false {

            let distanceFromEdge = scrollView.rubberBandingLength(from: targetEdge)
            let progressToTriggerRefreshing = max(
              0,
              min(1, distanceFromEdge / Constants.rubberBandingLengthToTriggerRefreshing)
            )

            let nextState = ActivatingState.triggering(progress: progressToTriggerRefreshing)

            if self.refreshingState != nextState {
              self.refreshingState = nextState
            }

            if progressToTriggerRefreshing == 1 {
              self._pullToRefresh_beginRefreshing()
            }

          }
        }
      }

    }
  }

  private func removeOffsetObservation() {
    offsetObservation?.invalidate()
    offsetObservation = nil
  }

  // MARK: - Utility

  private static func maximumContentOffset(of scrollView: UIScrollView) -> CGPoint {

    let contentInset = scrollView.adjustedContentInset.subtracting(
      scrollView._scrollEdgeControl_localContentInset
    )

    return .init(
      x: scrollView.contentSize.width - scrollView.bounds.width + contentInset.right,
      y: scrollView.contentSize.height - scrollView.bounds.height + contentInset.bottom
    )
  }

  private static func isScrollableVertically(scrollView: UIScrollView) -> Bool {

    let contentInset = scrollView._userContentInset
    return
      (scrollView.bounds.height - scrollView.contentSize.height - contentInset.top
      - contentInset.bottom) < 0

  }

  private static func isScrollableHorizontally(scrollView: UIScrollView) -> Bool {

    let contentInset = scrollView._userContentInset
    return
      (scrollView.bounds.width - scrollView.contentSize.width - contentInset.left
      - contentInset.right) < 0

  }

}

extension UIScrollView {

  fileprivate func distance(from edge: ScrollEdgeControl.Edge) -> CGFloat {

    switch edge {
    case .top:
      return -(contentOffset.y + adjustedContentInset.top)
    case .bottom:
      let contentOffsetMaxY = (bounds.height + contentOffset.y)
      return -(contentSize.height - contentOffsetMaxY + adjustedContentInset.bottom)
    case .left:
      return -(contentOffset.x + adjustedContentInset.left)
    case .right:
      let contentOffsetMaxX = (bounds.width + contentOffset.x)
      return -(contentSize.width - contentOffsetMaxX + adjustedContentInset.right)
    }

  }

  fileprivate func rubberBandingLength(from edge: ScrollEdgeControl.Edge) -> CGFloat {

    switch edge {
    case .top, .left:
      return distance(from: edge)
    case .bottom:
      let margin = max(
        0,
        bounds.height - contentSize.height - adjustedContentInset.top - adjustedContentInset.bottom
      )
      let contentOffsetMaxY = (bounds.height + contentOffset.y - margin)
      let value = -(contentSize.height - contentOffsetMaxY + adjustedContentInset.bottom)
      return value
    case .right:
      let margin = max(
        0,
        bounds.width - contentSize.width - adjustedContentInset.left - adjustedContentInset.right
      )
      let contentOffsetMaxX = (bounds.width + contentOffset.x - margin)
      let value = -(contentSize.width - contentOffsetMaxX + adjustedContentInset.right)
      return value
    }

  }

}

/**
 Special tricks (swizzling)
 */
extension UIScrollView {

  private enum Associated {
    static var _valueContainerAssociated: Void?
    static var localContentInset: Void?
    static var userContentInset: Void?
  }

  /// Returns a Boolean value that indicates wheter swizzling has been completed.
  fileprivate static let swizzle: Bool = {

    method_exchangeImplementations(
      class_getInstanceMethod(UIScrollView.self, #selector(setter:UIScrollView.contentInset))!,
      class_getInstanceMethod(
        UIScrollView.self,
        #selector(UIScrollView.__scrollEdgeControl_setContentInset)
      )!
    )

    method_exchangeImplementations(
      class_getInstanceMethod(UIScrollView.self, #selector(getter:UIScrollView.contentInset))!,
      class_getInstanceMethod(
        UIScrollView.self,
        #selector(UIScrollView.__scrollEdgeControl_contentInset)
      )!
    )

    return true

  }()

  private final class Handlers {
    var onSetContentInset: ((UIScrollView, UIEdgeInsets) -> UIEdgeInsets)?
    var onGetContentInset: ((UIScrollView, UIEdgeInsets) -> UIEdgeInsets)?
  }

  fileprivate(set) var _scrollEdgeControl_localContentInset: UIEdgeInsets {
    get {
      return (objc_getAssociatedObject(self, &Associated.localContentInset) as? UIEdgeInsets)
        ?? .zero
    }
    set {

      if handlers.onSetContentInset == nil {
        handlers.onSetContentInset = { [weak self] scrollView, contentInset in
          guard let self = self else { return scrollView.contentInset }
          return contentInset.adding(self._scrollEdgeControl_localContentInset)
        }
      }

      if handlers.onGetContentInset == nil {
        handlers.onGetContentInset = { [weak self] scrollView, originalContentInset in
          guard let self = self else { return scrollView.contentInset }
          return self._userContentInset
        }
      }

      objc_setAssociatedObject(
        self,
        &Associated.localContentInset,
        newValue,
        .OBJC_ASSOCIATION_COPY_NONATOMIC
      )
    }
  }

  private var handlers: Handlers {

    assert(Thread.isMainThread)

    if let associated = objc_getAssociatedObject(self, &Associated._valueContainerAssociated)
      as? Handlers
    {
      return associated
    } else {
      let associated = Handlers()

      objc_setAssociatedObject(
        self,
        &Associated._valueContainerAssociated,
        associated,
        .OBJC_ASSOCIATION_RETAIN
      )
      return associated
    }
  }

  var __original_contentInset: UIEdgeInsets {
    get {
      /// call UIScrollView.contentInset.get
      __scrollEdgeControl_contentInset()
    }
    set {
      /// call UIScrollView.contentInset.set
      __scrollEdgeControl_setContentInset(newValue)
    }
  }

  /// content-inset without local-content-inset
  fileprivate var _userContentInset: UIEdgeInsets {
    get {
      return (objc_getAssociatedObject(self, &Associated.userContentInset) as? UIEdgeInsets)
        ?? .zero
    }
    set {
      objc_setAssociatedObject(
        self,
        &Associated.userContentInset,
        newValue,
        .OBJC_ASSOCIATION_COPY_NONATOMIC
      )
    }
  }

  /// [swizzling]
  /// Called from `UIScrollView.contentInset.set`
  @objc private dynamic func __scrollEdgeControl_setContentInset(_ contentInset: UIEdgeInsets) {

    ScrollEdgeControl.Log.debug("Set contentInset \(contentInset)")

    _userContentInset = contentInset

    guard let handler = handlers.onSetContentInset else {
      self.__scrollEdgeControl_setContentInset(contentInset)
      return
    }

    let manipulated = handler(self, contentInset)

    /// call actual method
    self.__scrollEdgeControl_setContentInset(manipulated)
  }

  @objc private dynamic func __scrollEdgeControl_contentInset() -> UIEdgeInsets {

    /// call actual method
    let originalContentInset = self.__scrollEdgeControl_contentInset()

    guard let handler = handlers.onGetContentInset else {
      /// call actual method
      return self.__scrollEdgeControl_contentInset()
    }

    return handler(self, originalContentInset)
  }

}

extension UIEdgeInsets {

  subscript(edge edge: ScrollEdgeControl.Edge) -> CGFloat {
    _read {
      switch edge {
      case .top: yield top
      case .right: yield right
      case .left: yield left
      case .bottom: yield bottom
      }
    }
    _modify {
      switch edge {
      case .top:
        yield &top
      case .right:
        yield &right
      case .left:
        yield &left
      case .bottom:
        yield &bottom
      }

    }
  }
}

private final class ScrollController {

  private var scrollObserver: NSKeyValueObservation!
  private(set) var isLocking: Bool = false
  private var previousValue: CGPoint?

  init(
    scrollView: UIScrollView
  ) {
    scrollObserver = scrollView.observe(\.contentOffset, options: .old) {
      [weak self, weak _scrollView = scrollView] scrollView, change in

      guard let scrollView = _scrollView else { return }
      guard let self = self else { return }
      self.handleScrollViewEvent(scrollView: scrollView, change: change)
    }
  }

  deinit {
    endTracking()
  }

  func lockScrolling() {
    isLocking = true
  }

  func unlockScrolling() {
    isLocking = false
  }

  func endTracking() {
    unlockScrolling()
    scrollObserver.invalidate()
  }

  private func handleScrollViewEvent(
    scrollView: UIScrollView,
    change: NSKeyValueObservedChange<CGPoint>
  ) {

    guard let oldValue = change.oldValue else { return }

    guard isLocking else {
      return
    }

    guard scrollView.contentOffset != oldValue else { return }

    guard oldValue != previousValue else { return }

    previousValue = scrollView.contentOffset

    scrollView.setContentOffset(oldValue, animated: false)
  }

}

extension CGPoint {

  subscript(direction direction: ScrollEdgeControl.Edge.Direction) -> CGFloat {
    get {
      switch direction {
      case .vertical:
        return y
      case .horizontal:
        return x
      }
    }
    mutating set {
      switch direction {
      case .vertical:
        y = newValue
      case .horizontal:
        x = newValue
      }
    }
  }
}

extension UIEdgeInsets {

  fileprivate func adding(_ otherInsets: UIEdgeInsets) -> UIEdgeInsets {
    return .init(
      top: top + otherInsets.top,
      left: left + otherInsets.left,
      bottom: bottom + otherInsets.bottom,
      right: right + otherInsets.right
    )
  }

  fileprivate func subtracting(_ otherInsets: UIEdgeInsets) -> UIEdgeInsets {
    return .init(
      top: top - otherInsets.top,
      left: left - otherInsets.left,
      bottom: bottom - otherInsets.bottom,
      right: right - otherInsets.right
    )
  }

}
