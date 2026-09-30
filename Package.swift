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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601514743.zip",
      checksum: "f3730d0107f5d5ca59f000c7ba8e0225e4ea2621f8e8b296f91c70257bd988b7"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601514740.zip",
      checksum: "e479d2380341008633724df79c64cfd683df2ec6fa5f7f524c00505b9dd04c7f"
    ),
  ]
)
