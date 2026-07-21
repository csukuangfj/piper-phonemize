// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "piper-phonemize-example",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  dependencies: [
    // For remote package (default):
    .package(url: "https://github.com/csukuangfj/piper-phonemize.git", branch: "master"),
    // For local package (uncomment above, comment below):
    //.package(path: ".."),
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
