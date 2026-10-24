// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "MoneiTapToPay",
  platforms: [.iOS("18.5")],
  products: [
    .library(name: "MoneiTapToPay", targets: ["MoneiTapToPay", "CloudCommerce"])
  ],
  targets: [
    .binaryTarget(
      name: "MoneiTapToPay",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.3.0-beta.1/MoneiTapToPay.xcframework.zip",
      checksum: "32df0991675d5f04ed0a22c3e22a774d7b38388f928508432c6a60143159230e"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.3.0-beta.1/CloudCommerce.xcframework.zip",
      checksum: "e4693c22739480ecece5cf2c29962e2afc29dba935af19bb6847e82c012bdcf6"
    ),
  ]
)
