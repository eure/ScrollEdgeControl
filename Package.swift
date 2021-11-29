// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "MondrianLayout",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "ScrollEdgeControl", type: .static, targets: ["ScrollEdgeControl"]),
  ],
  dependencies: [
    .package(url: "http://github.com/timdonnelly/Advance", from: "3.0.0")
  ],
  targets: [
    .target(
      name: "ScrollEdgeControl",
      dependencies: ["Advance"],
      path: "ScrollEdgeControl"
    )
  ]
)
