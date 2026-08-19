# piper-phonemize Gradle Kotlin DSL (KTS) Example

This directory demonstrates how to use piper-phonemize via Gradle with Kotlin DSL.

## Prerequisites

- JDK 8 or above
- Gradle 8.x+ (or use the included Gradle wrapper)

## How It Works

The `build.gradle.kts` **automatically detects** your OS and architecture at build time:

```kotlin
val osName = System.getProperty("os.name").lowercase()
val osArch = System.getProperty("os.arch").lowercase()

val targetNativeClassifier = when {
    osName.contains("mac") || osName.contains("darwin") -> {
        if (osArch == "aarch64" || osArch == "arm64") "osx-aarch64" else "osx-x64"
    }
    osName.contains("linux") -> {
        if (osArch == "aarch64" || osArch == "arm64") "linux-aarch64" else "linux-x64"
    }
    osName.contains("win") -> {
        if (osArch == "aarch64" || osArch == "arm64") "win-arm64" else "win-x64"
    }
    else -> throw GradleException("Unsupported OS: $osName, Arch: $osArch")
}
```

This means:
- **No manual configuration needed** — just run `./gradlew build`
- **Works on any platform** — macOS, Linux, Windows x64, Windows ARM64

## Build

```bash
cd java-api-examples/gradle-kts-examples
./gradlew build
```

## Run

```bash
./gradlew run
```

## Supported Platforms

| Platform | Architecture | Artifact |
|---|---|---|
| macOS | ARM64 (Apple Silicon) | `piper-phonemize-native-lib-osx-aarch64` |
| macOS | x64 (Intel) | `piper-phonemize-native-lib-osx-x64` |
| Linux | x64 | `piper-phonemize-native-lib-linux-x64` |
| Linux | ARM64 | `piper-phonemize-native-lib-linux-aarch64` |
| Windows | x64 | `piper-phonemize-native-lib-win-x64` |
| Windows | ARM64 | `piper-phonemize-native-lib-win-arm64` |
