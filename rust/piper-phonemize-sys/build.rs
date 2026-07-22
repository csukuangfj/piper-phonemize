use std::collections::HashSet;
use std::env;
use std::error::Error;
use std::ffi::{OsStr, OsString};
use std::fs;
use std::path::{Path, PathBuf};

use bzip2::read::BzDecoder;
use tar::Archive;

const RELEASE_BASE_URL: &str = "https://github.com/csukuangfj/piper-phonemize/releases/download";

const PIPER_PHONEMIZE_STATIC_LIBS: &[&str] = &[
    "piper_phonemize_core",
    "espeak-ng",
    "ucd",
];

type DynError = Box<dyn Error>;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum LinkMode {
    Static,
    Shared,
}

fn main() {
    if let Err(err) = try_main() {
        panic!("{err}");
    }
}

fn try_main() -> Result<(), DynError> {
    println!("cargo:rerun-if-env-changed=PIPER_PHONEMIZE_LIB_DIR");
    println!("cargo:rerun-if-env-changed=PIPER_PHONEMIZE_ARCHIVE_DIR");
    println!("cargo:rerun-if-env-changed=DOCS_RS");

    if env::var_os("DOCS_RS").is_some() {
        return Ok(());
    }

    let target_os = env::var("CARGO_CFG_TARGET_OS")?;
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH")?;
    let link_mode = resolve_link_mode()?;
    let lib_dir = resolve_lib_dir(link_mode, &target_os, &target_arch)?;

    println!("cargo:rustc-link-search=native={}", lib_dir.display());

    if link_mode == LinkMode::Shared
        && matches!(target_os.as_str(), "linux" | "macos" | "android")
    {
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir.display());
        emit_relative_rpath(&target_os);
        copy_unix_runtime_libs(&lib_dir, &target_os)?;
    }

    if link_mode == LinkMode::Shared && target_os == "windows" {
        copy_windows_runtime_dlls(&lib_dir)?;
    }

    match link_mode {
        LinkMode::Static => emit_static_link_directives(&target_os),
        LinkMode::Shared => emit_shared_link_directives(&target_os),
    }

    download_espeak_ng_data()?;

    Ok(())
}

fn resolve_link_mode() -> Result<LinkMode, DynError> {
    let static_enabled = env::var_os("CARGO_FEATURE_STATIC").is_some();
    let shared_enabled = env::var_os("CARGO_FEATURE_SHARED").is_some();

    if static_enabled && shared_enabled {
        return Err("Features `static` and `shared` cannot be enabled at the same time".into());
    }

    if shared_enabled {
        Ok(LinkMode::Shared)
    } else {
        Ok(LinkMode::Static)
    }
}

fn resolve_lib_dir(
    link_mode: LinkMode,
    target_os: &str,
    target_arch: &str,
) -> Result<PathBuf, DynError> {
    // Option 1: Use PIPER_PHONEMIZE_LIB_DIR if set
    if let Ok(lib_dir) = env::var("PIPER_PHONEMIZE_LIB_DIR") {
        let p = PathBuf::from(&lib_dir);
        if p.is_dir() {
            return Ok(p);
        }
        return Err(format!("PIPER_PHONEMIZE_LIB_DIR={lib_dir} is not a directory").into());
    }

    // Option 2: Download prebuilt libraries from GitHub releases
    download_prebuilt_libs(link_mode, target_os, target_arch)
}

fn download_prebuilt_libs(
    link_mode: LinkMode,
    target_os: &str,
    target_arch: &str,
) -> Result<PathBuf, DynError> {
    let archive_name = archive_name(link_mode, target_os, target_arch)?;
    let archive_stem = archive_name.trim_end_matches(".tar.bz2");

    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    let cache_root = target_dir_from_out_dir(&out_dir)?.join("piper-phonemize-prebuilt");
    let extracted_dir = cache_root.join(archive_stem);
    let lib_dir = extracted_dir.join("lib");

    if lib_dir.is_dir() {
        return Ok(lib_dir);
    }

    // Android shared: jniLibs/{abi}/
    let android_shared_dir = extracted_dir.join("jniLibs").join(android_abi(target_arch));
    if android_shared_dir.is_dir() {
        return Ok(android_shared_dir);
    }

    // Android static: libs/{abi}/
    let android_static_dir = extracted_dir.join("libs").join(android_abi(target_arch));
    if android_static_dir.is_dir() {
        return Ok(android_static_dir);
    }

    fs::create_dir_all(&cache_root)?;

    let archive_path = cache_root.join(&archive_name);
    if !archive_path.is_file() {
        if let Some(local_archive_dir) = env::var_os("PIPER_PHONEMIZE_ARCHIVE_DIR") {
            let local_archive_path = PathBuf::from(local_archive_dir).join(&archive_name);
            if !local_archive_path.is_file() {
                return Err(format!(
                    "PIPER_PHONEMIZE_ARCHIVE_DIR does not contain expected archive: {}",
                    local_archive_path.display()
                )
                .into());
            }
            copy_file_atomically(&local_archive_path, &archive_path)?;
        } else {
            let version = "1.4.7";
            let url = format!("{RELEASE_BASE_URL}/v{version}/{archive_name}");
            eprintln!("Downloading piper-phonemize libs from {url}");

            let response = ureq::get(&url)
                .call()
                .map_err(|e| format!("Failed to download archive from {url}: {e}"))?;
            let mut reader = response.into_reader();
            write_reader_atomically(&mut reader, &archive_path)?;
        }
    }

    if extracted_dir.exists() {
        fs::remove_dir_all(&extracted_dir)?;
    }

    // Unpack to cache_root (archives have flat structure with lib/, include/, jniLibs/)
    let unpack_result: Result<(), DynError> = (|| {
        let tar_file = fs::File::open(&archive_path)?;
        let decoder = BzDecoder::new(tar_file);
        let mut archive = Archive::new(decoder);
        archive.unpack(&cache_root)?;
        Ok(())
    })();
    if let Err(err) = unpack_result {
        let _ = fs::remove_file(&archive_path);
        let _ = fs::remove_dir_all(&extracted_dir);
        return Err(format!(
            "Failed to unpack cached archive {}: {err}",
            archive_path.display()
        )
        .into());
    }

    // Check Android shared: jniLibs/{abi}/
    let android_shared_dir = cache_root.join("jniLibs").join(android_abi(target_arch));
    if android_shared_dir.is_dir() {
        return Ok(android_shared_dir);
    }

    // Check Android static: libs/{abi}/
    let android_static_dir = cache_root.join("libs").join(android_abi(target_arch));
    if android_static_dir.is_dir() {
        return Ok(android_static_dir);
    }

    // Check lib/ subdirectory (desktop platforms) - unpacked to cache_root
    let desktop_lib_dir = cache_root.join("lib");
    if desktop_lib_dir.is_dir() && target_os != "android" {
        return Ok(desktop_lib_dir);
    }

    Err(format!(
        "Downloaded archive did not contain expected libraries at {}",
        cache_root.display()
    )
    .into())
}

fn android_abi(target_arch: &str) -> &str {
    match target_arch {
        "aarch64" => "arm64-v8a",
        "arm" => "armeabi-v7a",
        "x86" => "x86",
        "x86_64" => "x86_64",
        _ => "arm64-v8a",
    }
}

fn archive_name(
    link_mode: LinkMode,
    target_os: &str,
    target_arch: &str,
) -> Result<String, DynError> {
    let version = "1.4.7";
    let name = match (link_mode, target_os, target_arch) {
        (LinkMode::Static, "linux", "x86_64") => {
            format!("piper-phonemize-v{version}-linux-x64-static-lib.tar.bz2")
        }
        (LinkMode::Static, "linux", "aarch64") => {
            format!("piper-phonemize-v{version}-linux-arm64-static-lib.tar.bz2")
        }
        (LinkMode::Static, "macos", "x86_64") => {
            format!("piper-phonemize-v{version}-macos-x64-static-lib.tar.bz2")
        }
        (LinkMode::Static, "macos", "aarch64") => {
            format!("piper-phonemize-v{version}-macos-arm64-static-lib.tar.bz2")
        }
        (LinkMode::Static, "windows", "x86_64") => {
            format!("piper-phonemize-v{version}-windows-x64-static-lib.tar.bz2")
        }
        (LinkMode::Shared, "linux", "x86_64") => {
            format!("piper-phonemize-v{version}-linux-x64-shared-lib.tar.bz2")
        }
        (LinkMode::Shared, "linux", "aarch64") => {
            format!("piper-phonemize-v{version}-linux-arm64-shared-lib.tar.bz2")
        }
        (LinkMode::Shared, "macos", "x86_64") => {
            format!("piper-phonemize-v{version}-macos-x64-shared-lib.tar.bz2")
        }
        (LinkMode::Shared, "macos", "aarch64") => {
            format!("piper-phonemize-v{version}-macos-arm64-shared-lib.tar.bz2")
        }
        (LinkMode::Shared, "windows", "x86_64") => {
            format!("piper-phonemize-v{version}-windows-x64-shared-lib.tar.bz2")
        }
        // Android: one archive with all ABIs
        (LinkMode::Shared, "android", "aarch64" | "arm" | "x86" | "x86_64") => {
            format!("piper-phonemize-v{version}-android.tar.bz2")
        }
        (LinkMode::Static, "android", "aarch64" | "arm" | "x86" | "x86_64") => {
            format!("piper-phonemize-v{version}-android-static-lib.tar.bz2")
        }
        _ => {
            return Err(format!(
                "Unsupported target: os={target_os}, arch={target_arch}, link_mode={:?}",
                link_mode
            )
            .into())
        }
    };

    Ok(name)
}

fn emit_static_link_directives(target_os: &str) {
    for lib in PIPER_PHONEMIZE_STATIC_LIBS {
        println!("cargo:rustc-link-lib=static={lib}");
    }

    match target_os {
        "linux" => {
            println!("cargo:rustc-link-lib=stdc++");
            println!("cargo:rustc-link-lib=m");
            println!("cargo:rustc-link-lib=gcc_s");
        }
        "android" => {
            println!("cargo:rustc-link-lib=c++");
            println!("cargo:rustc-link-lib=m");
        }
        "macos" => {
            println!("cargo:rustc-link-lib=c++");
        }
        "windows" => {}
        _ => {}
    }
}

fn emit_shared_link_directives(target_os: &str) {
    println!("cargo:rustc-link-lib=dylib=piper_phonemize_core");
    if target_os == "android" {
        println!("cargo:rustc-link-lib=dylib=espeak-ng");
        println!("cargo:rustc-link-lib=dylib=ucd");
    }
}

fn target_dir_from_out_dir(out_dir: &Path) -> Result<PathBuf, DynError> {
    if let Ok(target_dir) = env::var("CARGO_TARGET_DIR") {
        return Ok(PathBuf::from(target_dir));
    }

    if let Some(target_dir) = out_dir
        .ancestors()
        .find(|p| p.file_name() == Some(std::ffi::OsStr::new("target")))
    {
        return Ok(target_dir.to_path_buf());
    }

    Ok(out_dir.to_path_buf())
}

fn copy_file_atomically(src: &Path, dst: &Path) -> Result<(), DynError> {
    let temp_path = dst.with_extension("tmp");
    fs::copy(src, &temp_path)?;
    fs::rename(&temp_path, dst)?;
    Ok(())
}

fn write_reader_atomically(reader: &mut dyn std::io::Read, dst: &Path) -> Result<(), DynError> {
    let temp_path = dst.with_extension("tmp");
    {
        let mut file = fs::File::create(&temp_path)?;
        std::io::copy(reader, &mut file)?;
        file.sync_all()?;
    }
    fs::rename(&temp_path, dst)?;
    Ok(())
}

fn emit_relative_rpath(target_os: &str) {
    match target_os {
        "linux" | "android" => println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN"),
        "macos" => println!("cargo:rustc-link-arg=-Wl,-rpath,@loader_path"),
        _ => {}
    }
}

fn profile_output_dirs() -> Result<[PathBuf; 2], DynError> {
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    let profile = env::var("PROFILE")?;
    let profile_dir = out_dir
        .ancestors()
        .find(|path| path.file_name() == Some(OsStr::new(&profile)))
        .ok_or_else(|| {
            format!(
                "Could not locate Cargo profile directory from {}",
                out_dir.display()
            )
        })?
        .to_path_buf();

    Ok([profile_dir.clone(), profile_dir.join("examples")])
}

fn copy_unix_runtime_libs(lib_dir: &Path, target_os: &str) -> Result<(), DynError> {
    let runtime_libs: Vec<PathBuf> = fs::read_dir(lib_dir)?
        .filter_map(|entry| entry.ok().map(|e| e.path()))
        .filter(|path| {
            path.file_name()
                .and_then(OsStr::to_str)
                .map(|name| match target_os {
                    "linux" | "android" => name.contains(".so"),
                    "macos" => name.ends_with(".dylib"),
                    _ => false,
                })
                .unwrap_or(false)
        })
        .collect();

    if runtime_libs.is_empty() {
        return Ok(());
    }

    let mut copy_plan = Vec::<(PathBuf, OsString)>::new();
    let mut planned_names = HashSet::<OsString>::new();

    for lib in runtime_libs {
        if !lib.exists() {
            continue;
        }

        let lib_name = lib
            .file_name()
            .ok_or_else(|| format!("Invalid runtime library path: {}", lib.display()))?
            .to_os_string();

        let source = fs::canonicalize(&lib).unwrap_or(lib.clone());
        if planned_names.insert(lib_name.clone()) {
            copy_plan.push((source.clone(), lib_name));
        }

        if let Some(source_name) = source.file_name() {
            let source_name = source_name.to_os_string();
            if planned_names.insert(source_name.clone()) {
                copy_plan.push((source.clone(), source_name));
            }
        }
    }

    for dest_dir in profile_output_dirs()? {
        fs::create_dir_all(&dest_dir)?;
        for (source, dest_name) in &copy_plan {
            let dest = dest_dir.join(dest_name);
            fs::copy(source, &dest)?;
        }
    }

    Ok(())
}

fn copy_windows_runtime_dlls(lib_dir: &Path) -> Result<(), DynError> {
    let dlls: Vec<PathBuf> = fs::read_dir(lib_dir)?
        .filter_map(|entry| entry.ok().map(|e| e.path()))
        .filter(|path| path.extension() == Some(OsStr::new("dll")))
        .collect();

    if dlls.is_empty() {
        return Ok(());
    }

    let [profile_dir, examples_dir] = profile_output_dirs()?;
    for dest_dir in [profile_dir.clone(), examples_dir] {
        fs::create_dir_all(&dest_dir)?;
        for dll in &dlls {
            let dest = dest_dir.join(
                dll.file_name()
                    .ok_or_else(|| format!("Invalid DLL path: {}", dll.display()))?,
            );
            fs::copy(dll, &dest)?;
        }
    }

    Ok(())
}

fn download_espeak_ng_data() -> Result<(), DynError> {
    let out_dir = env::var("OUT_DIR")?;
    let dest = PathBuf::from(&out_dir).join("espeak-ng-data.tar.bz2");

    if dest.exists() {
        return Ok(());
    }

    let url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2";
    eprintln!("Downloading espeak-ng-data from {url}...");
    let resp = ureq::get(url).call()?;
    let mut bytes = Vec::new();
    use std::io::Read;
    resp.into_reader().read_to_end(&mut bytes)?;

    fs::write(&dest, &bytes)?;
    Ok(())
}
