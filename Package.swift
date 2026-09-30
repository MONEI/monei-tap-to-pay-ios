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
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601674742.zip",
      checksum: "0a670711929a96eb163f686765652a9c1069e5a4176fd2cccb8af9c18c8ee04e"
    ),
    .binaryTarget(
      name: "CloudCommerce",
      url: "https://api.github.com/repos/MONEI/monei-tap-to-pay-ios-spm/releases/assets/601674743.zip",
      checksum: "f4d273d76de733b3dfa74780829d04915d341a785fda12760428e94a5e80bd80"
    ),
  ]
)
