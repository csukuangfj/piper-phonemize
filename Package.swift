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
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.11-macos.xcframework.zip",
      checksum: "42ccfb055bb637b3cad4350a0593f385dbd5aed9013521f88dd3d980ac17080c"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.11-ios.xcframework.zip",
      checksum: "03d41c7b6841cf0d848e73e2b9d852cfd879b96cc408ae71d69b2ddd3c3a4afc"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.11-macos-shared.xcframework.zip",
      checksum: "3485e4002c55bd42bfa3e42f1cb8ef679e34aaca8d1d28b4de04e2db337e26e5"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.4.11-ios-shared.xcframework.zip",
      checksum: "33a4274cbcb421cffb37bbbb1ff83da526c82b0ca5115c241cf206ea8c07b715"
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
