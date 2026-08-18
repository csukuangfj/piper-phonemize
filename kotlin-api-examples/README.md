# piper-phonemize Kotlin API Examples

This directory contains examples for the Kotlin API of piper-phonemize.

## Usage

```bash
cd kotlin-api-examples
bash run.sh
```

## How it works

The `run.sh` script:
1. Builds the JNI shared library if not exists
2. Compiles Kotlin sources using `kotlinc-jvm`
3. Runs the example with `java -Djava.library.path=...`

## Supported platforms

Same as the Java API — Linux, macOS, Windows (x64 and ARM64).
