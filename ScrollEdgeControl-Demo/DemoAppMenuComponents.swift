//

import Foundation
import AsyncDisplayKit
import TextureSwiftSupport
import TypedTextAttributes
import GlossButtonNode
import RxSwift
import RxCocoa

#if canImport(StorybookKit)

public enum DemoAppMenuComponents {

  public static func makeSelectionCell(
    title: String,
    description: String? = nil,
    onTap: @escaping () -> Void
  ) -> ASCellNode {

    let button = GlossButtonNode()
    button.setHaptics(.impactOnTouchUpInside())
    button.onTap = onTap

    let descriptionLabel = ASTextNode()
    descriptionLabel.attributedText = description.map {
      NSAttributedString(
        string: $0,
        attributes: [
          .font: UIFont.systemFont(ofSize: 12),
          .foregroundColor: UIColor.lightGray,
        ]
      )
    }

    button.setDescriptor(
      .init(
        title: NSAttributedString(
          string: title,
          attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.systemBlue,
          ]
        ),
        image: nil,
        bodyStyle: .init(layout: .vertical()),
        surfaceStyle: .fill(
          .init(
            cornerRound: .radius(all: 4),
            backgroundColor: .fill(.init(white: 0, alpha: 0.1)),
            dropShadow: nil
          )
        ),
        insets: .init(top: 8, left: 4, bottom: 8, right: 4)
      ),
      for: .normal
    )

    return WrapperCellNode {
      return AnyDisplayNode { _, _ in

        LayoutSpec {
          VStackLayout(spacing: 8) {
            HStackLayout {
              button
                .flexShrink(1)
                .flexGrow(1)
            }
            if description != nil {
              descriptionLabel
            }
          }
          .padding(.horizontal, 2)
          .padding(.vertical, 2)
        }
      }
    }
  }
}

#endif
