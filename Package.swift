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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.3.0/MoneiTapToPay.xcframework.zip",
      checksum: "6c032b94737cdfcacb1b0338d31708ecd7ad098b2bfd4843d9fe6e5f6761c861"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.3.0/CloudCommerce.xcframework.zip",
      checksum: "f944d92badadf58d7c878150b6bf9ccdd7775335b8c76e314629bc4d7636cb60"
    ),
  ]
)
