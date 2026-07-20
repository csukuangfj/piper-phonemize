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
    .binaryTarget(
      name: "espeak-ng-data",
      url: "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.zip",
      checksum: "bc4525eafe31b4e3f5e43aea495f3169e97dd2544f1bbfe95514ce8a61baee39"
    ),
    .target(
      name: "piper-phonemize",
      dependencies: ["piper-phonemize-core", "espeak-ng-data"],
      path: "swift-api-examples",
      sources: ["PiperPhonemize.swift"]
    ),
  ]
)
