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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/602635825.zip",
      checksum: "e044a94686cce2f5ecaeb8272b15bbf5fc1dec0aecaeb992e3177aa8536a96b9"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/602635827.zip",
      checksum: "5010b56633296a4de25a326c90cb1f99fa3bbd1221b7d5106bdcdf40fac40652"
    ),
  ]
)
