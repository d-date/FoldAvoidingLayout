// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "FoldAvoidingLayout",
  platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .visionOS(.v1)],
  products: [
    .library(name: "FoldAvoidingLayout", targets: ["FoldAvoidingLayout"])
  ],
  targets: [
    .target(name: "FoldAvoidingLayout"),
    .testTarget(name: "FoldAvoidingLayoutTests", dependencies: ["FoldAvoidingLayout"]),
  ]
)
