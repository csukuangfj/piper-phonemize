// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "piper-phonemize",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    // Static xcframework (default)
    .library(name: "piper-phonemize", targets: ["piper_phonemize"]),
    // Shared/dynamic xcframework
    .library(name: "piper-phonemize-shared", targets: ["piper_phonemize_shared"]),
  ],
  targets: [
    // --- Static binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.9-macos.xcframework.zip",
      checksum: "63690882cc49724bc602bd6f554ad8bf10ad73624636881a686855d077f32ace"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.9-ios.xcframework.zip",
      checksum: "3c7dd0d4fc432b4310042fca9730fb0f0bd24eb09a5f58d3499a9c756fa8bf05"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.9-macos-shared.xcframework.zip",
      checksum: "b3de34acf32e607a4108dcc5d9ae0bcd4e7962b7475e657ac1d9c06e4c89252d"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.9-ios-shared.xcframework.zip",
      checksum: "0fac6e63def6c4c85919e2d87c026272c5753239e55a41f492c5a6da25c22aff"
    ),

    // --- Static wrapper target (default) ---
    .target(
      name: "piper_phonemize",
      dependencies: [
        .target(name: "PiperPhonemizeMacOS", condition: .when(platforms: [.macOS])),
        .target(name: "PiperPhonemizeIOS", condition: .when(platforms: [.iOS])),
      ],
      path: "swift-api-examples",
      exclude: ["example.swift", "example", "run.sh", "PiperPhonemize-Bridging-Header.h"],
      sources: ["PiperPhonemize.swift"],
      resources: [.copy("espeak-ng-data")],
      linkerSettings: [.linkedLibrary("c++")]
    ),

    // --- Shared wrapper target ---
    .target(
      name: "piper_phonemize_shared",
      dependencies: [
        .target(name: "PiperPhonemizeMacOSShared", condition: .when(platforms: [.macOS])),
        .target(name: "PiperPhonemizeIOSShared", condition: .when(platforms: [.iOS])),
      ],
      path: "Sources/PiperPhonemizeShared",
      resources: [.copy("espeak-ng-data")],
      linkerSettings: [.linkedLibrary("c++")]
    ),
  ]
)
