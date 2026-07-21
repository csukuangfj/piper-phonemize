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
      checksum: "9c62ef2959c895e194d05efbd3ae2128fc5e393d3d4c41f55cec0e4436ab0cb4"
    ),
    .target(
      name: "piper-phonemize",
      dependencies: ["piper-phonemize-core"],
      path: "swift-api-examples",
      exclude: ["example.swift", "example", "run.sh", "PiperPhonemize-Bridging-Header.h"],
      resources: [
        .copy("espeak-ng-data")
      ]
    ),
  ]
)
