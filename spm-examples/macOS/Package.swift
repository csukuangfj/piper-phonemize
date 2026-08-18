// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PiperPhonemizeExample",
  platforms: [.macOS(.v10_15)],
  dependencies: [
    .package(url: "https://github.com/csukuangfj/piper-phonemize.git", branch: "master"),
  ],
  targets: [
    .executableTarget(
      name: "PiperPhonemizeExample",
      dependencies: [
        .product(name: "piper-phonemize", package: "piper-phonemize"),
      ]
    )
  ]
)
