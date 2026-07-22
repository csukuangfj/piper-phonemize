# Piper Phonemize - Tauri Example

A cross-platform desktop/mobile app built with [Tauri v2](https://tauri.app) that
demonstrates the `piper-phonemize` Rust crate. The app provides a GUI for converting
text to IPA phonemes using espeak-ng, supporting 110 languages.

Supports **macOS**, **Windows**, **Linux**, and **Android**.

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (1.77+)
- [Tauri CLI](https://tauri.app/start/prerequisites/):
  ```bash
  cargo install tauri-cli
  ```
- Platform-specific dependencies (see [Tauri prerequisites](https://tauri.app/start/prerequisites/)):
  - **macOS**: Xcode command line tools
  - **Windows**: Microsoft Visual Studio C++ Build Tools
  - **Linux**: `libwebkit2gtk-4.1-dev`, `build-essential`, `curl`, `wget`, `file`, `libxdo-dev`, `libssl-dev`, `libayatana-appindicator3-dev`, `librsvg2-dev`
  - **Android**: Android Studio, Android SDK, NDK

## Run (Desktop)

```bash
# Development mode (hot reload)
cargo tauri dev

# Build release
cargo tauri build
```

## Download Pre-built Apps

Pre-built apps are available on the
[GitHub Releases](https://github.com/csukuangfj/piper-phonemize/releases) page.

| Platform | File |
|---|---|
| macOS (Apple Silicon) | `piper-phonemize-tauri-macos-arm64.app.zip` |
| macOS (Intel) | `piper-phonemize-tauri-macos-x64.app.zip` |
| Linux (x64) | `piper-phonemize-tauri-linux-x64.tar.bz2` |
| Linux (arm64) | `piper-phonemize-tauri-linux-arm64.tar.bz2` |
| Windows (x64) | `piper-phonemize-tauri-windows-x64.zip` |
| Android | `piper-phonemize-tauri_1.4.7_aarch64.apk` |

### Download Links

| Platform | File | Size |
|---|---|---|
| macOS (Apple Silicon) | [piper-phonemize-tauri-macos-arm64.app.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-macos-arm64.app.zip) | |
| macOS (Intel) | [piper-phonemize-tauri-macos-x64.app.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-macos-x64.app.zip) | |
| Linux (x64) | [piper-phonemize-tauri-linux-x64.tar.bz2](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-linux-x64.tar.bz2) | |
| Linux (arm64) | [piper-phonemize-tauri-linux-arm64.tar.bz2](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-linux-arm64.tar.bz2) | |
| Windows (x64) | [piper-phonemize-tauri-windows-x64.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-windows-x64.zip) | |
| Android (APK) | [app-universal-release-unsigned.apk](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/app-universal-release-unsigned.apk) | |

### macOS Gatekeeper

The pre-built macOS app is not code-signed. After unzipping, you may see
"is damaged and can't be opened." Fix with:

```bash
# For Apple Silicon
xattr -cr piper-phonemize-tauri-macos-arm64.app

# For Intel
xattr -cr piper-phonemize-tauri-macos-x64.app
```

Or right-click the app → Open to bypass Gatekeeper.

## Run (Android)

### 1. Set environment variables

Tauri needs `ANDROID_HOME` and `NDK_HOME` to find the Android SDK and NDK.
If you have already built the Android native libraries (see `../build-android*.sh`),
your SDK and NDK are likely at:

```bash
export ANDROID_HOME=$HOME/software/my-android/sdk
export NDK_HOME=$HOME/software/my-android/ndk/29.0.14206865
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
```

Adjust the paths if your installation differs. Add these to your shell profile
(`~/.zshrc` or `~/.bashrc`) to make them permanent.

### 2. Symlink NDK if needed

Tauri expects the NDK to be inside `$ANDROID_HOME/ndk/`. If your NDK is in a
separate directory, create a symlink:

```bash
mkdir -p $ANDROID_HOME/ndk
ln -s $NDK_HOME $ANDROID_HOME/ndk/$(basename $NDK_HOME)
```

### 3. Initialize and run

`cargo tauri android init` will automatically install all 4 Android Rust targets
(arm, arm64, x86, x86_64) on first run. This is a one-time download and may take
a few minutes. Subsequent runs will skip this step.

```bash
# Initialize Android project (first time only, installs Rust targets)
cargo tauri android init
```

### 4. Fix Gradle JDK (if needed)

If your system JDK is too new for Gradle (e.g. JDK 25), add the path to Android
Studio's bundled JDK in `src-tauri/gen/android/gradle.properties`:

```properties
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

### 5. Run

```bash
# Run on connected device/emulator
cargo tauri android dev

# Build APK
cargo tauri android build
```

## How It Works

1. The **frontend** (`src/index.html`) is a single HTML file with a voice selector
   (110 languages), text input, and results display.
2. The **Rust backend** (`src-tauri/src/lib.rs`) exposes two Tauri commands:
   - `get_version()` — returns the piper-phonemize version
   - `phonemize(text, voice)` — converts text to IPA phonemes
3. The `piper-phonemize` Rust crate handles everything: espeak-ng data is
   embedded at compile time and auto-extracted at runtime. No manual setup needed.

## Project Structure

```
tauri-examples/
├── src/
│   └── index.html              # Frontend UI
├── src-tauri/
│   ├── Cargo.toml              # Rust dependencies
│   ├── tauri.conf.json         # Tauri configuration
│   ├── build.rs                # Tauri build script
│   ├── src/
│   │   ├── lib.rs              # Tauri commands
│   │   └── main.rs             # Entry point
│   ├── capabilities/
│   │   └── default.json        # Webview permissions
│   └── icons/                  # App icons
└── README.md
```
