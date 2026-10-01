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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.2.0/MoneiTapToPay.xcframework.zip",
      checksum: "bd4738e6c64f580fd50260ec959b16577c54a04a4fa16c3750af89cc1b8bdfcf"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.2.0/CloudCommerce.xcframework.zip",
      checksum: "6148c80bb4372f53a98b7c407f08aaff9b04c1d41bcf60846a50c2f28e21c7cf"
    ),
  ]
)
