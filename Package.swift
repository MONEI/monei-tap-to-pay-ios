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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.1.1/MoneiTapToPay.xcframework.zip",
      checksum: "a412609248ca15b6abec27ef6f8fb3f437e3e3fc4db4189512a3e92328512af1"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.1.1/CloudCommerce.xcframework.zip",
      checksum: "1f8f0f9adb10c02e83bfb31040386e15b071359c1dbb0e0fb7623aa66bf35be6"
    ),
  ]
)
