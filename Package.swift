// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "ScrollEdgeControl",
  platforms: [.iOS(.v13)],
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
