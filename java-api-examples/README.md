# Introduction

This directory contains examples for the Java API of piper-phonemize.

## Supported platforms

| OS | Architecture | Status |
|---|---|---|
| Linux | x64 | ✅ |
| Linux | ARM64 | ✅ |
| macOS | x64 (Intel) | ✅ |
| macOS | ARM64 (Apple Silicon) | ✅ |
| Windows | x64 | ✅ |
| Windows | ARM64 | ✅ |

# Usage

## Build and run the Java example

```bash
cd java-api-examples
bash run-phonemize-text.sh
```

## Maven example

```bash
cd maven-examples
mvn package -q
java -jar target/piper-phonemize-maven-example-1.4.9.jar
```

## Gradle example

```bash
cd gradle-examples
./gradlew build
./gradlew run
```

## Gradle KTS example

```bash
cd gradle-kts-examples
./gradlew build
./gradlew run
```
