import StorybookKit

let book = Book(title: "MyBook") {
  BookSection(title: "Vertical") {
    BookPush(title: "Top") {
      DemoVerticalViewController(
        configuration: .init(topConfiguration: .init(), bottomConfiguration: nil)
      )
    }
    BookPush(title: "Bottom") {
      DemoVerticalViewController(
        configuration: .init(topConfiguration: nil, bottomConfiguration: .init())
      )
    }
    BookPush(title: "Both") {
      DemoVerticalViewController(
        configuration: .init(topConfiguration: .init(), bottomConfiguration: .init())
      )
    }
  }
}
