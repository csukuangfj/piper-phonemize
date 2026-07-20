// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "piper-phonemize-example",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  dependencies: [
    .package(url: "https://github.com/csukuangfj/piper-phonemize.git", from: "1.4.7"),
  ],
  targets: [
    .executableTarget(
      name: "piper-phonemize-example",
      dependencies: [
        .product(name: "piper-phonemize", package: "piper-phonemize"),
      ],
      path: "Sources"
    ),
  ]
)
