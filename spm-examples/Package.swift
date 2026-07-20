// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "piper-phonemize-example",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  dependencies: [
    // For testing with remote package:
    .package(url: "https://github.com/csukuangfj/piper-phonemize.git", branch: "master")
    // For testing with local package:
    //.package(path: "..")
  ],
  targets: [
    .executableTarget(
      name: "piper-phonemize-example",
      dependencies: [
        .product(name: "piper-phonemize", package: "piper-phonemize")
      ],
      path: "Sources"
    )
  ]
)
