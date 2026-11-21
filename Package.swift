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
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.6.1-macos.xcframework.zip",
      checksum: "16a232060d5795933bedd38e8339b5f57e6f51430ec99fefa3d04983402106fd"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.6.1-ios.xcframework.zip",
      checksum: "a868c591571bca2b1c69490ec30fafb420c5ac1749a3906840dcfe2757ddabb6"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.6.1-macos-shared.xcframework.zip",
      checksum: "a5fc4acc885231a48841334dacf802ae2af5403fb5d9b38bf4fae66b395303f2"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.6.1-ios-shared.xcframework.zip",
      checksum: "2c1c57cd97137222ae24d4ed4404cb16bd57085f426280e2af29212d9149467e"
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
