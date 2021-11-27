
import MondrianLayout
import UIKit
import ScrollEdgeControl

public final class DebuggingRefreshIndicatorView: UIView, ScrollEdgeActivityIndicatorViewType {

  private let label = UILabel()

  public init() {
    super.init(frame: .zero)

    let backgroundView = UIView()
    backgroundView.backgroundColor = .darkGray

    mondrian.buildSubviews {
      ZStackBlock {
        label
          .viewBlock
          .padding(4)
          .background(backgroundView)
      }
    }

    label.textColor = .white
    label.font = .systemFont(ofSize: 8)
  }

  required init?(
    coder: NSCoder
  ) {
    fatalError()
  }

  public func update(withState state: ScrollEdgeControl.RefreshingState) {

    switch state {
    case .triggering(let progress):
      label.text = "triggering \(progress)"
    case .refreshing:
      label.text = "refreshing"
    case .completedRefreshing:
      label.text = "completed"
    }
  }
}

