//

@testable import ScrollEdgeControl
import Foundation
import RxSwift
import TypedTextAttributes

import StorybookKit

enum ScrollEdgeControl_BookView {

  /*
  static var body: BookView {

    BookNavigationLink(title: "ScrollEdgeControl") {

      BookSection(title: "Horizontal") {

        BookPush(title: "Left") {
          HorizontalDemoViewController(edge: .left)
        }

        BookPush(title: "Right") {
          HorizontalDemoViewController(edge: .right)
        }

      }

      BookSection(title: "Vertical") {

        BookPush(title: "Bidirectional") {
          VerticalBidirectionalDemoController(options: [.usesTop, .usesBottom])
        }

        BookSection(title: "short") {

          BookPush(title: "top bottom") {
            VerticalBidirectionalDemoController(options: [.usesTop, .usesBottom], itemCount: 2)
          }

          BookPush(title: "top") {
            VerticalBidirectionalDemoController(options: [.usesTop], itemCount: 2)
          }

          BookPush(title: "bottom") {
            VerticalBidirectionalDemoController(options: [.usesBottom], itemCount: 2)
          }
        }

      }

      BookSection(title: "Others") {

        BookPush(title: "ContentInset Playground") {
          ContentInsetPlaygroundController()
        }

        BookPush(title: "UIRefreshControl") {
          UIRefreshControlDemoController()
        }
      }
    }

  }

  private final class MenuNode: ASDisplayNode {

    private let menuNode = StackScrollNode()
    private let disposeBag = DisposeBag()

    init(
      scrollDirection: UICollectionView.ScrollDirection
    ) {

      super.init()

      automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        menuNode
      }
    }

    @MainActor
    func setup(stackScrollNode: StackScrollNode, scrollEdgeControl: ScrollEdgeControl) {

      let scrollViewInfoNode = ASTextNode()

      menuNode.append(nodes: [

        DemoAppMenuComponents.makeSelectionCell(
          title: "Dump ScrollView",
          onTap: {
            print(
              """
              contentOffset: \(stackScrollNode.scrollView.contentOffset)
              contentInset: \(stackScrollNode.scrollView.contentInset)
              adjustedContentInset: \(stackScrollNode.scrollView.adjustedContentInset)
              """
            )
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "End",
          onTap: {
            scrollEdgeControl.setActivityState(.inactive, animated: false)
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Begin",
          onTap: {
            scrollEdgeControl.setActivityState(.active, animated: false)
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "End animated",
          onTap: {
            scrollEdgeControl.setActivityState(.inactive, animated: true)
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Begin animated",
          onTap: {
            scrollEdgeControl.setActivityState(.active, animated: true)
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentOffset -1000 to top",
          onTap: {
            stackScrollNode.scrollView.contentOffset.y = -1000
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentInset 100 to top",
          onTap: {
            stackScrollNode.scrollView.contentInset.top = 100
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentInset 0",
          onTap: {
            stackScrollNode.scrollView.contentInset.top = 0
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Increase top contentInset 10",
          onTap: {
            stackScrollNode.scrollView.contentInset.top += 10
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentInset 100 to bottom",
          onTap: {
            stackScrollNode.scrollView.contentInset.bottom = 100
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Increase bottom contentInset 10",
          onTap: {
            stackScrollNode.scrollView.contentInset.bottom += 10
          }
        ),

        WrapperCellNode {
          scrollViewInfoNode
        },

      ])

      do {

        Observable.from([
          stackScrollNode.scrollView.rx.observe(\.contentInset, options: [.initial, .old, .new]).map
          { _ in },
          stackScrollNode.scrollView.rx.observe(\.contentOffset, options: [.initial, .old, .new])
            .map { _ in },
        ])
        .merge()
        .subscribe(onNext: { [unowned scrollView = stackScrollNode.scrollView] _ in

          scrollViewInfoNode.attributedText = """
            adjustedContentInset: \(scrollView.adjustedContentInset)
            contentInset: \(scrollView.contentInset)
            contentOffset: \(scrollView.contentOffset)

            actualContentInset: \(scrollView.__original_contentInset)
            translation: \(scrollView.panGestureRecognizer.translation(in: nil).y)
            """.styled(.init())

        })
        .disposed(by: disposeBag)
      }

    }
  }

  private final class BidirectionalMenuNode: ASDisplayNode {

    private let menuNode = StackScrollNode()
    private let disposeBag = DisposeBag()

    init(
      scrollDirection: UICollectionView.ScrollDirection
    ) {

      super.init()

      automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        menuNode
      }
    }

    @MainActor
    func setup(
      stackScrollNode: StackScrollNode,
      scrollEdgeControlForStart: ScrollEdgeControl,
      scrollEdgeControlForEnd: ScrollEdgeControl
    ) {

      let scrollViewInfoNode = ASTextNode()

      menuNode.append(nodes: [

        DemoAppMenuComponents.makeSelectionCell(
          title: "Begin animated",
          onTap: {
            scrollEdgeControlForStart.setActivityState(.active, animated: true)
          }
        ),

        DemoAppMenuComponents.makeSelectionCell(
          title: "End animated",
          onTap: {
            scrollEdgeControlForStart.setActivityState(.inactive, animated: true)
          }
        ),

        DemoAppMenuComponents.makeSelectionCell(
          title: "Begin animated",
          onTap: {
            scrollEdgeControlForEnd.setActivityState(.active, animated: true)
          }
        ),

        DemoAppMenuComponents.makeSelectionCell(
          title: "End animated",
          onTap: {
            scrollEdgeControlForEnd.setActivityState(.inactive, animated: true)
          }
        ),

        DemoAppMenuComponents.makeSelectionCell(
          title: "Increase contentInset",
          onTap: {
            stackScrollNode.scrollView.contentInset.top += 10
            stackScrollNode.scrollView.contentInset.bottom += 10
          }
        ),

        DemoAppMenuComponents.makeSelectionCell(
          title: "Decrease contentInset",
          onTap: {
            stackScrollNode.scrollView.contentInset.top -= 10
            stackScrollNode.scrollView.contentInset.bottom -= 10
          }
        ),

        WrapperCellNode {
          scrollViewInfoNode
        },

      ])

      do {

        Observable.from([
          stackScrollNode.scrollView.rx.observe(\.contentInset, options: [.initial, .old, .new]).map
          { _ in },
          stackScrollNode.scrollView.rx.observe(\.contentOffset, options: [.initial, .old, .new])
            .map { _ in },
        ])
        .merge()
        .subscribe(onNext: { [unowned scrollView = stackScrollNode.scrollView] _ in

          scrollViewInfoNode.attributedText = """
            adjustedContentInset: \(scrollView.adjustedContentInset)
            contentInset: \(scrollView.contentInset)
            contentOffset: \(scrollView.contentOffset)

            local: \(scrollView._scrollEdgeControl_localContentInset)

            actualContentInset: \(scrollView.__original_contentInset)
            translation: \(scrollView.panGestureRecognizer.translation(in: nil).y)
            """.styled(.init())

        })
        .disposed(by: disposeBag)
      }

    }
  }

  private final class HorizontalDemoViewController: DisplayNodeViewController {

    private let menuNode = MenuNode(scrollDirection: .horizontal)
    private let contentNode = StackScrollNode(
      scrollDirection: .horizontal,
      spacing: 2,
      sectionInset: .zero
    )
    private let edge: ScrollEdgeControl.Edge

    init(
      edge: ScrollEdgeControl.Edge
    ) {
      self.edge = edge
      super.init()
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      view.backgroundColor = .white

      let cells = (0..<10).map { _ in
        makeHorizontalCell()
      }

      contentNode.append(nodes: cells)

      let scrollEdgeControl = ScrollEdgeControl(
        edge: edge,
        configuration: .init(),
        activityIndicatorView: ExampleRefreshIndicatorView()
      )

      contentNode.scrollView.addSubview(scrollEdgeControl)

      menuNode.setup(stackScrollNode: contentNode, scrollEdgeControl: scrollEdgeControl)

    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        VStackLayout {
          contentNode
            .height(120)
          menuNode
            .flexGrow(1)
        }
        .padding(capturedSafeAreaInsets)
      }
    }

  }

  private final class VerticalBidirectionalDemoController: DisplayNodeViewController {

    enum Option: Hashable {
      case usesTop
      case usesBottom
    }

    private let menuNode = BidirectionalMenuNode(scrollDirection: .vertical)

    private let contentNode = StackScrollNode(
      scrollDirection: .vertical,
      spacing: 2,
      sectionInset: .zero
    )

    private let setup: @MainActor (ScrollEdgeControl) -> Void

    private let disposeBag = DisposeBag()

    init(
      options: [Option],
      itemCount: Int = 10,
      setup: @MainActor @escaping (ScrollEdgeControl) -> Void = { _ in }
    ) {
      self.setup = setup
      super.init()

      view.backgroundColor = .white

      let cells = (0..<itemCount).map { _ in
        makeVerticalCell()
      }

      contentNode.append(nodes: cells)

      let scrollEdgeControlForStart = ScrollEdgeControl(
        edge: .top,
        configuration: .init(),
        activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black)
      )

      let scrollEdgeControlForEnd = ScrollEdgeControl(
        edge: .bottom,
        configuration: .init(),
        activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black)
      )

      if options.contains(.usesTop) {

        contentNode.scrollView.addSubview(scrollEdgeControlForStart)

        scrollEdgeControlForStart.handlers.onDidBeginRefreshing = { control in
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            control.setActivityState(.inactive, animated: true)
          }
        }

        setup(scrollEdgeControlForStart)
      }

      if options.contains(.usesBottom) {

        contentNode.scrollView.addSubview(scrollEdgeControlForEnd)

        scrollEdgeControlForEnd.handlers.onDidBeginRefreshing = { control in
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            control.setActivityState(.inactive, animated: true)
          }
        }

        setup(scrollEdgeControlForEnd)
      }

      menuNode.setup(
        stackScrollNode: contentNode,
        scrollEdgeControlForStart: scrollEdgeControlForStart,
        scrollEdgeControlForEnd: scrollEdgeControlForEnd
      )

    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        HStackLayout {
          contentNode
            .flexGrow(0.5)
          menuNode
            .flexGrow(1)
        }
      }
    }

  }

  private static func makeVerticalCell() -> ASCellNode {

    WrapperCellNode {

      AnyDisplayNode { node, _ in

        LayoutSpec {
          VStackLayout {
            node._makeNode {
              let node = ASTextNode()
              node.attributedText = BookLorem.ipsum(100).styled(.init())
              return node
            }
            .padding(10)
            .background(
              node._makeNode {
                ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemOrange)
              }
            )
            .padding(2)
          }
        }

      }
    }
  }

  private static func makeHorizontalCell() -> ASCellNode {

    WrapperCellNode {

      AnyDisplayNode { node, _ in

        LayoutSpec {
          node._makeNode {
            let node = ASTextNode()
            node.attributedText = BookLorem.ipsum(20).styled(.init())
            return node
          }
          .padding(10)
          .background(
            node._makeNode {
              ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemYellow)
            }
          )
        }

      }
    }
  }

  fileprivate final class ContentInsetPlaygroundController: DisplayNodeViewController {

    private let menuNode = StackScrollNode()

    private let demoContentNode = StackScrollNode()

    override init() {
      super.init()
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      menuNode.append(nodes: [
        DemoAppMenuComponents.makeSelectionCell(
          title: "Hoge",
          onTap: {
            print("tap")
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Dump ScrollView",
          onTap: { [unowned self] in
            print(
              """
              contentOffset: \(demoContentNode.scrollView.contentOffset)
              contentInset: \(demoContentNode.scrollView.contentInset)
              adjustedContentInset: \(demoContentNode.scrollView.adjustedContentInset)
              """
            )
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentOffset -1000 to top",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentOffset.y = -1000
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Reset contentInset to zero",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentInset = .zero
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentInset 100 to top",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentInset.top = 100
            demoContentNode.scrollView.contentOffset.y =
              -(demoContentNode.scrollView.safeAreaInsets.top + 100)
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Increase top contentInset 10",
          onTap: { [unowned self] in
            print("### prev \(demoContentNode.scrollView.contentInset.top)")
            demoContentNode.scrollView.contentInset.top += 10
            demoContentNode.scrollView.contentOffset.y -= 10
            print("### current \(demoContentNode.scrollView.contentInset.top)")
          }
        ),
      ])

      view.backgroundColor = .white

      let cells = (0..<30).map { _ in
        Self.makeCell()
      }

      demoContentNode.append(nodes: cells)

      /**

       */
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        HStackLayout {
          demoContentNode
            .flexGrow(1)
          menuNode
            .flexBasis(fraction: 0.3)
        }
      }
    }

    private static func makeCell() -> ASCellNode {

      WrapperCellNode {

        AnyDisplayNode { node, _ in

          LayoutSpec {
            VStackLayout {
              node._makeNode {
                let node = ASTextNode()
                node.attributedText = BookLorem.ipsum(100).styled(.init())
                return node
              }
              .padding(10)
              .background(
                node._makeNode {
                  ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemYellow)
                }
              )
            }
          }

        }
      }
    }

  }

  fileprivate final class UIRefreshControlDemoController: DisplayNodeViewController {

    private var parentVC: UIViewController? = nil

    private var control: UIRefreshControl!

    private let demoContentNode = StackScrollNode()

    private let menuNode = StackScrollNode()

    private let disposeBag = DisposeBag()

    override func didMove(toParent parent: UIViewController?) {

      guard let parent = parent else { return }

      self.parentVC = parent
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      let scrollViewInfoNode = ASTextNode()

      menuNode.append(nodes: [
        DemoAppMenuComponents.makeSelectionCell(
          title: "Hoge",
          onTap: {
            print("tap")
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Dump ScrollView",
          onTap: { [unowned self] in
            print(
              """
              contentOffset: \(demoContentNode.scrollView.contentOffset)
              contentInset: \(demoContentNode.scrollView.contentInset)
              adjustedContentInset: \(demoContentNode.scrollView.adjustedContentInset)
              """
            )
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "End refreshing",
          onTap: { [unowned self] in
            control.endRefreshing()
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentOffset -1000 to top",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentOffset.y = -1000
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Set contentInset 100 to top",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentInset.top = 100
          }
        ),
        DemoAppMenuComponents.makeSelectionCell(
          title: "Increase top contentInset 10",
          onTap: { [unowned self] in
            demoContentNode.scrollView.contentInset.top += 10
          }
        ),

        WrapperCellNode {
          scrollViewInfoNode
        },
      ])

      view.backgroundColor = .white

      let cells = (0..<30).map { _ in
        makeVerticalCell()
      }

      demoContentNode.append(nodes: cells)

      /**

       */
      self.control = UIRefreshControl()

      if #available(iOS 14.0, *) {
        control.addAction(
          .init { _ in
            print("action")
          },
          for: .valueChanged
        )
      } else {
        // Fallback on earlier versions
      }

      demoContentNode.scrollView.addSubview(control)

      do {

        Observable.from([
          demoContentNode.scrollView.rx.observe(\.contentInset, options: [.initial, .old, .new]).map
          { _ in },
          demoContentNode.scrollView.rx.observe(\.contentOffset, options: [.initial, .old, .new])
            .map { _ in },
        ])
          .merge()
          .subscribe(onNext: { [unowned scrollView = demoContentNode.scrollView] _ in

            scrollViewInfoNode.attributedText = """
            adjustedContentInset: \(scrollView.adjustedContentInset)
            contentInset: \(scrollView.contentInset)
            contentOffset: \(scrollView.contentOffset)

            translation: \(scrollView.panGestureRecognizer.translation(in: nil).y)
            """.styled(.init())

          })
          .disposed(by: disposeBag)
      }

    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        HStackLayout {
          demoContentNode
            .flexGrow(1)
          menuNode
            .flexBasis(fraction: 0.3)
        }
      }
    }

  }
   */
}
