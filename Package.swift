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
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.5-macos.xcframework.zip",
      checksum: "18c6b27fe587b8d9b790de69df1380d1e26dc221b5a478ace4d4834fb271e461"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.5-ios.xcframework.zip",
      checksum: "0074275a2762b7d8b3daf5e5d33c2cecf1e53080f3fcf7052e85d129ec6bcd61"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.5-macos-shared.xcframework.zip",
      checksum: "6f124cdc6a49615cf93d80aa138675e7271b76c401c071bf6f418677eb6f3a2b"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.5-ios-shared.xcframework.zip",
      checksum: "58f12834825fd7aa2aadc59de7a4f17e14a126ed64011de12ebfc758da966d7e"
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
