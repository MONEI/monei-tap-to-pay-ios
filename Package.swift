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
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.5.0/MoneiTapToPay.xcframework.zip",
      checksum: "8be93dcb04074c07133edfed9777f75ddd0def025543bf88ce1e86af9a9c96c9"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://github.com/MONEI/monei-tap-to-pay-ios/releases/download/0.5.0/CloudCommerce.xcframework.zip",
      checksum: "1447d5783b049236682a2ff74dee27775ce3d096d55b783c70383056f7a1d327"
    ),
  ]
)
