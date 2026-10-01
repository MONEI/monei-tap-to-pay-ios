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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios/releases/assets/603009362.zip",
      checksum: "2f2e046cc36cc613b9c4bb41d5da1153a31fe02b1daf1f04cf6418de67b2127b"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios/releases/assets/603009367.zip",
      checksum: "40ceb5b90bdb598d0ec07dca37a115c03c14caad290b8510560e473239b0a2e3"
    ),
  ]
)
