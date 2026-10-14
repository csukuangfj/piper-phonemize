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
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.7-macos.xcframework.zip",
      checksum: "321496ed65854ddd52435879837a504d6f0e474d5306e7b7fe1b0fc776b117f2"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOS",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.7-ios.xcframework.zip",
      checksum: "dd7a5db014b485a2098f8c54c177088f8b12db67d852643aaa6cf097ab74f031"
    ),

    // --- Shared binary targets ---
    .binaryTarget(
      name: "PiperPhonemizeMacOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.7-macos-shared.xcframework.zip",
      checksum: "528a0b6e95d644bf03047f6c140ca1ffc66128b3d39cc578b6b188cb2c8a97c0"
    ),
    .binaryTarget(
      name: "PiperPhonemizeIOSShared",
      url:
        "https://github.com/csukuangfj/piper-phonemize/releases/download/xcframework/piper-phonemize-v1.5.7-ios-shared.xcframework.zip",
      checksum: "a0e638999dd5a6e034c94ce03ea9c47622ff7f1d057aca3947dabac555e284b1"
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
