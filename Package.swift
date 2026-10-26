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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.4.0/MoneiTapToPay.xcframework.zip",
      checksum: "57172465bec985e9464685260d6ff325da2044a5ee5444ec995c1a113c93e4d2"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.4.0/CloudCommerce.xcframework.zip",
      checksum: "f378172b59b64f20c560ff19f798e03088e1dea3cea3130eb4f7858f0fe25abb"
    ),
  ]
)
