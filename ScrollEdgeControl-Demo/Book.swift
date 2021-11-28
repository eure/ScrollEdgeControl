import StorybookKit

let book = Book(title: "MyBook") {
  BookNavigationLink(title: "Vertical") {

    let Controller = DemoVerticalViewController.self

    BookSection(title: "Pull to refresh") {
      BookPush(title: "Top") {
        Controller.init(
          configuration: .init(startSideConfiguration: .init(), endSideConfiguration: nil)
        )
      }
      BookPush(title: "Bottom") {
        Controller.init(
          configuration: .init(startSideConfiguration: nil, endSideConfiguration: .init())
        )
      }
      BookPush(title: "Both") {
        Controller.init(
          configuration: .init(startSideConfiguration: .init(), endSideConfiguration: .init())
        )
      }
    }

    BookSection(title: "Pull to refresh and tail loading") {
      BookPush(title: "Example") {
        let controller = Controller.init(
          configuration: .init(
            startSideConfiguration: .init(),
            endSideConfiguration: .init {
              $0.layoutMode = .scrollingAlongContent
              $0.pullToActivateMode = .disabled
            }
          )
        )

        controller.endScrollEdgeControl?.setActivityState(.active, animated: false)

        return controller
      }
    }

  }

  BookNavigationLink(title: "Horizontal") {

    let Controller = DemoHorizontalViewController.self

    BookPush(title: "Top") {
      Controller.init(
        configuration: .init(startSideConfiguration: .init(), endSideConfiguration: nil)
      )
    }
    BookPush(title: "Bottom") {
      Controller.init(
        configuration: .init(startSideConfiguration: nil, endSideConfiguration: .init())
      )
    }
    BookPush(title: "Both") {
      Controller.init(
        configuration: .init(startSideConfiguration: .init(), endSideConfiguration: .init())
      )
    }
  }
}
