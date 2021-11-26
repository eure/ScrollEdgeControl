import AsyncDisplayKit
import UIKit
#if canImport(StorybookKit)
import StorybookKit
#endif

/// A view that shows that a task is in progress.
public final class DonutsIndicatorView: UIView {

  public enum Size: CaseIterable {
    case medium
    case small

    var intrinsicContentSize: CGSize {
      switch self {
      case .medium:
        return CGSize(width: 22, height: 22)
      case .small:
        return CGSize(width: 12, height: 12)
      }
    }
  }

  public struct Color {

    public let placeholderColor: UIColor
    public let tickColor: UIColor

    public static let white: Color = .init(
      placeholderColor: UIColor(white: 1, alpha: 0.1),
      tickColor: UIColor(white: 1, alpha: 0.2)
    )

    public static let black: Color = .init(
      placeholderColor: UIColor(white: 0, alpha: 0.1),
      tickColor: UIColor(white: 0, alpha: 0.2)
    )
  }

  // MARK: - Properties

  private let placeholderShapeLayer = CAShapeLayer()
  private let tickShapeLayer = CAShapeLayer()

  public let size: Size
  public let color: Color

  /// A boolean value that indicates the animation is running.
  /// And it indicates also whether the animation would be restored when re-enter hiererchy.
  public private(set) var isAnimating: Bool = false

  private var currentAnimator: UIViewPropertyAnimator?

  public override var intrinsicContentSize: CGSize {
    size.intrinsicContentSize
  }

  // MARK: - Initializers

  public init(
    size: Size,
    color: Color = .black
  ) {

    self.size = size
    self.color = color

    super.init(frame: .zero)

    let lineWidth: CGFloat

    switch size {
    case .medium:
      lineWidth = 3
    case .small:
      lineWidth = 2
    }

    do {
      layer.addSublayer(placeholderShapeLayer)

      placeholderShapeLayer.fillColor = UIColor.clear.cgColor
      placeholderShapeLayer.lineWidth = lineWidth
    }

    do {

      layer.addSublayer(tickShapeLayer)

      tickShapeLayer.fillColor = UIColor.clear.cgColor
      tickShapeLayer.strokeStart = 0
      tickShapeLayer.strokeEnd = 0.2
      tickShapeLayer.lineCap = .round
      tickShapeLayer.lineWidth = lineWidth
    }

    self.alpha = 0

    setColor(color)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setColor(_ color: Color) {
    tickShapeLayer.strokeColor = color.tickColor.cgColor
    placeholderShapeLayer.strokeColor = color.placeholderColor.cgColor
  }

  // MARK: - Functions

  /// Starts the animation with throttling
  ///
  /// - TODO: adds a flag to disable throttling that indicates animation appears immediately.
  public func startAnimating() {

    assert(Thread.isMainThread)

    guard !isAnimating else { return }

    isAnimating = true
    _startAnimating()

    let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1) {
      self.alpha = 1
    }

    currentAnimator?.stopAnimation(true)

    animator.startAnimation()

    currentAnimator = animator

  }

  /// Stops the animation with throttling
  ///
  /// - TODO: adds a flag to disable throttling that indicates animation disappears immediately.
  public func stopAnimating() {

    assert(Thread.isMainThread)

    guard isAnimating else {
      return
    }

    isAnimating = false

    let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) {
      self.alpha = 0
    }

    animator.addCompletion { _ in
      self._stopAnimating()
    }

    currentAnimator?.stopAnimation(true)
    currentAnimator = animator

    animator.startAnimation()

  }

  private func _startAnimating() {

    let rotate = CABasicAnimation(keyPath: "transform.rotation.z")

    rotate.fromValue = 0
    rotate.toValue = CGFloat.pi * 2
    rotate.repeatCount = .infinity

    let group = CAAnimationGroup()
    group.animations = [
      rotate
    ]
    group.duration = 0.4
    group.repeatCount = .infinity

    tickShapeLayer.add(group, forKey: "animation")

  }

  private func _stopAnimating() {

    tickShapeLayer.removeAnimation(forKey: "animation")
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil, isAnimating {
      _startAnimating()
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    placeholderShapeLayer.frame = self.layer.bounds
    tickShapeLayer.frame = self.layer.bounds
    let path = UIBezierPath(
      roundedRect: self.layer.bounds,
      cornerRadius: .infinity
    )
    placeholderShapeLayer.path = path.cgPath
    tickShapeLayer.path = path.cgPath
  }

}

public final class DonutsIndicatorFractionView: UIView {

  public typealias Size = DonutsIndicatorView.Size

  public typealias Color = DonutsIndicatorView.Color

  // MARK: - Properties

  private let placeholderShapeLayer = CAShapeLayer()
  private let tickShapeLayer = CAShapeLayer()

  public let size: Size
  public let color: Color

  public override var intrinsicContentSize: CGSize {
    size.intrinsicContentSize
  }

  // MARK: - Initializers

  public init(
    size: Size,
    color: Color = .black
  ) {

    self.size = size
    self.color = color

    super.init(frame: .zero)

    let lineWidth: CGFloat

    switch size {
    case .medium:
      lineWidth = 3
    case .small:
      lineWidth = 2
    }

    do {
      layer.addSublayer(placeholderShapeLayer)

      placeholderShapeLayer.fillColor = UIColor.clear.cgColor
      placeholderShapeLayer.lineWidth = lineWidth
    }

    do {

      layer.addSublayer(tickShapeLayer)

      tickShapeLayer.fillColor = UIColor.clear.cgColor
      tickShapeLayer.strokeStart = 0
      tickShapeLayer.strokeEnd = 0
      tickShapeLayer.lineCap = .round
      tickShapeLayer.lineWidth = lineWidth
    }

    self.alpha = 0

    setColor(color)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Functions
  
  public func setColor(_ color: Color) {
    tickShapeLayer.strokeColor = color.tickColor.cgColor
    placeholderShapeLayer.strokeColor = color.placeholderColor.cgColor
  }

  private let progressAnimation = CASpringAnimation(
    keyPath: #keyPath(CAShapeLayer.strokeEnd),
    damping: 1,
    response: 0.1
  )

  public func setProgress(_ progress: CGFloat) {

    tickShapeLayer.removeAnimation(forKey: "progress")

    progressAnimation.fromValue = tickShapeLayer.presentation()?.strokeEnd
    progressAnimation.toValue = max(0, min(1, progress))
    progressAnimation.isAdditive = true
    progressAnimation.fillMode = .both
    progressAnimation.isRemovedOnCompletion = false

    tickShapeLayer.add(progressAnimation, forKey: "progress")

  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    placeholderShapeLayer.frame = self.layer.bounds
    tickShapeLayer.frame = self.layer.bounds
    let path = UIBezierPath(
      roundedRect: self.layer.bounds,
      cornerRadius: .infinity
    )
    placeholderShapeLayer.path = path.cgPath
    tickShapeLayer.path = path.cgPath
  }

}


#if canImport(TextureSwiftSupport)
import TextureSwiftSupport

/// A node that shows that a task is in progress.
public final class DonutsIndicatorNode: ViewNode<DonutsIndicatorView> {

  public init(
    size: DonutsIndicatorView.Size,
    color: DonutsIndicatorView.Color = .black
  ) {
    super.init {
      let s = DonutsIndicatorView(size: size, color: color)
      return s
    }
    backgroundColor = .clear
    style.preferredSize = size.intrinsicContentSize
  }

  public func startAnimating() {
    ASPerformBlockOnMainThread {
      self.wrappedView.startAnimating()
    }
  }

  public func stopAnimating() {
    ASPerformBlockOnMainThread {
      self.wrappedView.stopAnimating()
    }
  }

}

#endif

extension CASpringAnimation {

  /**
   Creates an instance from damping and response.
   the response calucation comes from https://medium.com/@nathangitter/building-fluid-interfaces-ios-swift-9732bb934bf5
   */
  public convenience init(
    keyPath path: String?,
    damping: CGFloat,
    response: CGFloat,
    initialVelocity: CGFloat = 0
  ) {
    let stiffness = pow(2 * .pi / response, 2)
    let damp = 4 * .pi * damping / response

    self.init(keyPath: path)
    self.mass = 1
    self.stiffness = stiffness
    self.damping = damp
    self.initialVelocity = initialVelocity

  }
}
