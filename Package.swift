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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.6.0/MoneiTapToPay.xcframework.zip",
      checksum: "9a9700560f09fe4929278fa1249cee466b8934ef53bfcd2d1cdaa60182530e83"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.6.0/CloudCommerce.xcframework.zip",
      checksum: "e4006dbd73be443249c98dc506a49837876e9533d69a06dfae2a72ae29c5c790"
    ),
  ]
)
