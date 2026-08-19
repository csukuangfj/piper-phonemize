# piper-phonemize Maven Example

This directory demonstrates how to use piper-phonemize via Maven.

## Prerequisites

- JDK 8 or above
- Maven 3.x

## Dependencies

The project uses [JitPack](https://jitpack.io/) to fetch piper-phonemize artifacts.

### Multi-module (recommended)

```xml
<repositories>
    <repository>
        <id>jitpack.io</id>
        <url>https://jitpack.io</url>
    </repository>
</repositories>

<!-- 1. JVM core API -->
<dependency>
    <groupId>com.github.csukuangfj.piper-phonemize</groupId>
    <artifactId>piper-phonemize-jvm</artifactId>
    <version>v1.4.7</version>
</dependency>

<!-- 2. Platform native lib — pick ONE for your target platform -->
<dependency>
    <groupId>com.github.csukuangfj.piper-phonemize</groupId>
    <artifactId>piper-phonemize-native-lib-osx-aarch64</artifactId>
    <version>v1.4.7</version>
</dependency>
```

Available native lib artifacts:

| Platform | Artifact |
|---|---|
| macOS ARM64 | `piper-phonemize-native-lib-osx-aarch64` |
| macOS x64 | `piper-phonemize-native-lib-osx-x64` |
| Linux x64 | `piper-phonemize-native-lib-linux-x64` |
| Linux ARM64 | `piper-phonemize-native-lib-linux-aarch64` |
| Windows x64 | `piper-phonemize-native-lib-win-x64` |
| Windows ARM64 | `piper-phonemize-native-lib-win-arm64` |

## Build

```bash
cd java-api-examples/maven-examples
mvn package -q
```

## Run

```bash
java -jar target/piper-phonemize-maven-example-1.4.7.jar
```
