# Piper Phonemize Android Demo

This is an Android demo app showing how to use the piper-phonemize AAR library.

## Features

- **Language selection**: Dropdown with 113 supported espeak-ng languages
- **Example texts**: Pre-loaded example sentences for each language
- **Phonemization**: Convert text to IPA phonemes
- **Results display**: Shows phonemes, word count, and elapsed time

## Dependencies

Uses [JitPack](https://jitpack.io/) to fetch the AAR:

```kotlin
// settings.gradle.kts
maven { url = uri("https://jitpack.io") }

// app/build.gradle.kts
implementation("com.github.csukuangfj.piper-phonemize:piper-phonemize:v1.4.7")
```

## Build

```bash
cd android-demo
./gradlew assembleRelease
```

## Install

```bash
adb install app/build/outputs/apk/release/app-release.apk
```

## APK

The APK contains all 4 Android ABIs:
- arm64-v8a
- armeabi-v7a
- x86_64
- x86

Download pre-built APK from the [releases](https://github.com/csukuangfj/piper-phonemize/releases/tag/apk) page.
