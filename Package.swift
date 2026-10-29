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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.7.0/MoneiTapToPay.xcframework.zip",
      checksum: "e9a952dbb45ea7af7e8d00715c53621aa32b676f2427b8f3233a819a202199d7"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.7.0/CloudCommerce.xcframework.zip",
      checksum: "02107a31677eef5d4f8ba6fe2e63278e6b392b403c06f0ccda33630c57bb3169"
    ),
  ]
)
