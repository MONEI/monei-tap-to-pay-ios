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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601756100.zip",
      checksum: "b4342a638f3b3a45e5565c9ea203cb65af554e3a949d87d9c0ecc4cf02367803"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601756102.zip",
      checksum: "e2e51397a1c3641961dc711cd0b4756f1e11e98b3e71729372eda6309db20ec4"
    ),
  ]
)
