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
    .library(name: "piper-phonemize", targets: ["PiperPhonemize"]),
    // Shared/dynamic xcframework
    .library(name: "piper-phonemize-shared", targets: ["PiperPhonemizeShared"]),
  ],
  targets: [
    // --- Static binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOS",
      url: "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.7-macos.xcframework.zip",
      checksum: "0000000000000000000000000000000000000000000000000000000000000000"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url: "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.7-ios.xcframework.zip",
      checksum: "0000000000000000000000000000000000000000000000000000000000000000"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url: "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.7-macos-shared.xcframework.zip",
      checksum: "0000000000000000000000000000000000000000000000000000000000000000"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url: "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.7-ios-shared.xcframework.zip",
      checksum: "0000000000000000000000000000000000000000000000000000000000000000"
    ),

    // --- Static wrapper target (default) ---
    .target(
      name: "PiperPhonemize",
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
      name: "PiperPhonemizeShared",
      dependencies: [
        .target(name: "PiperPhonemizeMacOSShared", condition: .when(platforms: [.macOS])),
        .target(name: "PiperPhonemizeIOSShared", condition: .when(platforms: [.iOS])),
      ],
      path: "swift-api-examples",
      exclude: ["example.swift", "example", "run.sh", "PiperPhonemize-Bridging-Header.h"],
      sources: ["PiperPhonemize.swift"],
      resources: [.copy("espeak-ng-data")],
      linkerSettings: [.linkedLibrary("c++")]
    ),
  ]
)
