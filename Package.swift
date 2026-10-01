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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios/releases/assets/602655568.zip",
      checksum: "a820ee0246e047b4cc0f043e8d5996d247cb2159e0fb5ec15d1c21366b6ce624"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios/releases/assets/602655571.zip",
      checksum: "556a179401e0693a72edcb3928f84d5d55b27a88ac3e9c55adc00b9bc6298535"
    ),
  ]
)
