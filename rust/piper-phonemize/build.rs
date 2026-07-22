use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-env-changed=PIPER_PHONEMIZE_LIB_DIR");

    // Find the espeak-ng-data.tar.bz2 from the -sys crate's output
    let out_dir = env::var("OUT_DIR").unwrap();
    let target_dir = PathBuf::from(&out_dir)
        .ancestors()
        .find(|p| p.ends_with("target"))
        .unwrap_or(PathBuf::from(&out_dir).as_path())
        .to_path_buf();

    // Search for espeak-ng-data.tar.bz2 in the build directory
    let data_path = find_espeak_ng_data(&target_dir);

    match data_path {
        Some(p) => {
            println!("cargo:rustc-env=ESPEAK_NG_DATA_PATH={}", p.display());
        }
        None => {
            // Data not found yet - will be available after -sys crate builds
            println!("cargo:warning=espeak-ng-data.tar.bz2 not found, will be available after piper-phonemize-sys builds");
        }
    }

    // Set rpath for shared linking so the binary can find .dylib/.so at runtime.
    // cargo:rustc-link-arg from -sys crate doesn't propagate to dependents,
    // so we need to set it here.
    if env::var("CARGO_FEATURE_SHARED").is_ok() {
        let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
        if matches!(target_os.as_str(), "linux" | "macos") {
            // Find the lib directory from the -sys crate's prebuilt cache
            if let Some(lib_dir) = find_prebuilt_lib_dir(&target_dir) {
                println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir.display());
            }
        }
    }
}

fn find_espeak_ng_data(dir: &std::path::Path) -> Option<PathBuf> {
    for entry in walkdir::WalkDir::new(dir)
        .max_depth(5)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.file_name().to_string_lossy() == "espeak-ng-data.tar.bz2" {
            return Some(entry.path().to_path_buf());
        }
    }
    None
}

fn find_prebuilt_lib_dir(target_dir: &std::path::Path) -> Option<PathBuf> {
    // Check PIPER_PHONEMIZE_LIB_DIR first (from-source builds)
    if let Ok(lib_dir) = env::var("PIPER_PHONEMIZE_LIB_DIR") {
        let p = PathBuf::from(lib_dir);
        if p.is_dir() {
            return Some(p);
        }
    }
    // Check prebuilt cache (downloaded libs)
    let prebuilt = target_dir.join("piper-phonemize-prebuilt").join("lib");
    if prebuilt.is_dir() {
        return Some(prebuilt);
    }
    None
}
