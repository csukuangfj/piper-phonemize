# Tauri Examples - Development & Debug Notes

## How This Project Was Created

### 1. Project Structure (manual creation)

The project was created manually (not scaffolded by `create-tauri-app`) with this structure:

```
tauri-examples/
├── src/
│   └── index.html              # Frontend UI (vanilla HTML, no framework)
├── src-tauri/
│   ├── Cargo.toml              # Rust dependencies
│   ├── tauri.conf.json         # Tauri app config
│   ├── build.rs                # tauri_build::build()
│   ├── src/
│   │   ├── lib.rs              # Tauri commands (phonemize, get_version)
│   │   └── main.rs             # Entry point
│   ├── capabilities/
│   │   └── default.json        # Webview permissions
│   └── icons/                  # App icons (generated with PIL)
├── README.md
├── debug-note.md               # This file
├── run.sh
└── .gitignore
```

### 2. Key Dependencies

**`src-tauri/Cargo.toml`:**
```toml
[dependencies]
tauri = { version = "2", features = [] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
piper-phonemize = { path = "../../rust/piper-phonemize" }
```

### 3. Tauri Commands (Rust → JS bridge)

**`src-tauri/src/lib.rs`:**
```rust
#[command]
fn get_version() -> String {
    piper_phonemize::get_version()
}

#[command]
fn phonemize(text: String, voice: String) -> Result<Vec<String>, String> {
    piper_phonemize::phonemize_to_string(&text, &voice)
        .ok_or_else(|| format!("Failed to phonemize text with voice '{}'", voice))
}
```

### 4. Frontend → Rust Communication

In `src/index.html`, the JS calls Rust commands via:
```javascript
const { invoke } = window.__TAURI__.core;
const version = await invoke('get_version');
const sentences = await invoke('phonemize', { text, voice });
```

The `withGlobalTauri: true` in `tauri.conf.json` exposes `window.__TAURI__` without needing npm packages.

---

## Desktop Development

```bash
# Development mode (hot reload for frontend)
cargo tauri dev

# Build release app
cargo tauri build
```

---

## Android Development

### Environment Setup

```bash
export ANDROID_HOME=$HOME/software/my-android/sdk
export NDK_HOME=$HOME/software/my-android/ndk/29.0.14206865
export PATH=$ANDROID_HOME/platform-tools:$PATH
```

### Symlink NDK (if separate from SDK)

```bash
mkdir -p $ANDROID_HOME/ndk
ln -s $NDK_HOME $ANDROID_HOME/ndk/$(basename $NDK_HOME)
```

### Initialize Android Project

```bash
cargo tauri android init
```

This generates `src-tauri/gen/android/` with the Android Studio project.

### Fix Gradle JDK (if system JDK is too new)

If `cargo tauri android dev` fails with `Unsupported class file major version 69`,
add this to `src-tauri/gen/android/gradle.properties`:

```properties
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

This uses Android Studio's bundled JDK 21 instead of the system JDK.

### Build & Run

```bash
# Run on connected device/emulator
cargo tauri android dev

# Build APK
cargo tauri android build
```

---

## Debugging with ADB

### Check Connected Devices

```bash
adb devices
```

### View Logs (logcat)

```bash
# All logs
adb logcat

# Filter by app package
adb logcat | grep "piper.phonemize.tauri_examples"

# Filter for crashes
adb logcat | grep -iE "FATAL|AndroidRuntime|UnsatisfiedLink|panic"

# Filter for Rust stdout/stderr
adb logcat | grep "RustStdoutStderr"

# Clear logcat buffer
adb logcat -c

# Show last N lines
adb logcat -d -t 100
```

### Common Crash Patterns

**Symbol not found:**
```
dlopen failed: cannot locate symbol "PiperPhonemizeInitialize"
```
→ Wrong architecture static libs linked. Check `piper-phonemize-sys/build.rs` ABI selection.

**C++ stdlib mismatch:**
```
cannot locate symbol "_ZNSt6__ndk15mutexD1Ev"
```
→ Linking `libstdc++` instead of `c++` (NDK's libc++). Fix in `build.rs`:
```rust
"android" => {
    println!("cargo:rustc-link-lib=c++");  // not stdc++
    println!("cargo:rustc-link-lib=m");
}
```

**espeak-ng data not found:**
```
Failed to extract espeak-ng-data: Failed to read espeak-ng-data.tar.bz2
```
→ `ESPEAK_NG_DATA_PATH` points to build machine path. Fix: use `include_bytes!`
to embed the data in the binary instead of reading from filesystem.

**Mutex destroyed (right-click/long-press):**
```
FORTIFY: pthread_mutex_lock called on a destroyed mutex
```
→ Native WebView bug on Android. Workaround: use `<div>` instead of `<textarea>`
for output display to avoid triggering context menu.

### Check if App is Running

```bash
adb shell pidof com.piper.phonemize.tauri.examples
```

### Launch App Manually

```bash
adb shell am start -n com.piper.phonemize.tauri.examples/.MainActivity
```

### Install/Uninstall

```bash
# Uninstall
adb uninstall com.piper.phonemize.tauri.examples

# Install APK
adb install path/to/app.apk
```

### Capture Crash (Workflow)

```bash
# 1. Clear logcat
adb logcat -c

# 2. Launch app
adb shell am start -n com.piper.phonemize.tauri.examples/.MainActivity

# 3. Reproduce the crash

# 4. Capture logs
adb logcat -d | grep -iE "FATAL|AndroidRuntime|UnsatisfiedLink|panic|mutex|FORTIFY"
```

---

## Issues Encountered & Fixes

### 1. `gcc_s` not found on Android

**Error:** `ld.lld: error: unable to find library -lgcc_s`

**Fix:** Separate Android from Linux in `piper-phonemize-sys/build.rs`:
```rust
"android" => {
    println!("cargo:rustc-link-lib=c++");
    println!("cargo:rustc-link-lib=m");
    // no gcc_s
}
```

### 2. Gradle doesn't support system JDK

**Error:** `Unsupported class file major version 69`

**Fix:** Set `org.gradle.java.home` in `gen/android/gradle.properties` to Android Studio's JDK.

### 3. espeak-ng data path wrong on Android

**Error:** `Failed to read espeak-ng-data.tar.bz2`

**Fix:** Use `include_bytes!(env!("ESPEAK_NG_DATA_PATH"))` to embed data in binary.

### 4. Right-click crashes app on Android

**Error:** `FORTIFY: pthread_mutex_lock called on a destroyed mutex`

**Fix:** Replace output `<textarea>` with `<div>` to avoid native context menu trigger.

### 5. Prebuilt libs wrong architecture

**Error:** `cannot locate symbol "PiperPhonemizeInitialize"`

**Fix:** In `download_prebuilt_libs()`, check Android ABIs before `cache_root/lib/`
fallback, and guard fallback with `target_os != "android"`.

### 6. IPA characters show as white boxes

**Fix:** Use `font-family: sans-serif` which maps to Noto Sans on Android with
full Unicode/IPA support.
