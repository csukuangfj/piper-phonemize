// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "piper-phonemize",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(
      name: "piper-phonemize",
      targets: ["piper-phonemize"]
    ),
  ],
  targets: [
    .binaryTarget(
      name: "piper-phonemize-core",
      url: "https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-macos.xcframework.zip",
      checksum: "6281994f4bbc9573defe96bf237038dcedc3acc863ba65e428a49192b23809f7"
    ),
    .target(
      name: "piper-phonemize",
      dependencies: ["piper-phonemize-core"],
      path: "swift-api-examples",
      sources: ["PiperPhonemize.swift"],
      resources: [
        .copy("espeak-ng-data")
      ]
    ),
  ]
)
