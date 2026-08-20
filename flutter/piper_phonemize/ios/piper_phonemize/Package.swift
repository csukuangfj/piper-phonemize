// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "piper_phonemize",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    .library(name: "piper-phonemize", targets: ["piper_phonemize"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .binaryTarget(
      name: "PiperPhonemizeC",
      path: "piper-phonemize.xcframework"
    ),
    .target(
      name: "piper_phonemize",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        "PiperPhonemizeC",
      ]
    )
  ]
)
