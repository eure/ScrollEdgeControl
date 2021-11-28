// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "MondrianLayout",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "ScrollEdgeControl", type: .static, targets: ["ScrollEdgeControl"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "ScrollEdgeControl",
      dependencies: [],
      path: "ScrollEdgeControl"
    )
  ]
)
