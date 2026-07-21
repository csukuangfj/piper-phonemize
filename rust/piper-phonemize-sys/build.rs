use std::env;
use std::error::Error;
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

    if link_mode == LinkMode::Shared && matches!(target_os.as_str(), "linux" | "macos") {
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir.display());
    }

    match link_mode {
        LinkMode::Static => emit_static_link_directives(&target_os),
        LinkMode::Shared => emit_shared_link_directives(),
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
    let version = env!("CARGO_PKG_VERSION");
    let suffix = match link_mode {
        LinkMode::Static => "static",
        LinkMode::Shared => "shared",
    };
    let os = if target_os == "linux" {
        "linux"
    } else if target_os == "macos" {
        "macos"
    } else if target_os == "windows" {
        "windows"
    } else {
        return Err(format!("unsupported OS: {target_os}").into());
    };
    let arch = if target_arch == "x86_64" {
        "x64"
    } else if target_arch == "aarch64" {
        "arm64"
    } else if target_arch == "x86" {
        "x86"
    } else {
        return Err(format!("unsupported arch: {target_arch}").into());
    };

    let archive_stem = format!("piper-phonemize-v{version}-{os}-{arch}-{suffix}-lib");
    let archive_name = format!("{archive_stem}.tar.bz2");

    // Check cache
    let target_dir = env::var("OUT_DIR")?;
    let cache_root = Path::new(&target_dir)
        .ancestors()
        .find(|p| p.ends_with("target"))
        .unwrap_or(Path::new(&target_dir))
        .join("piper-phonemize-prebuilt");
    let extracted_dir = cache_root.join(&archive_stem);
    let lib_dir = extracted_dir.join("lib");

    if lib_dir.is_dir() {
        return Ok(lib_dir);
    }

    // Check PIPER_PHONEMIZE_ARCHIVE_DIR (for CI pre-seeding)
    if let Ok(archive_dir) = env::var("PIPER_PHONEMIZE_ARCHIVE_DIR") {
        let archive_path = Path::new(&archive_dir).join(&archive_name);
        if archive_path.exists() {
            return extract_archive(&archive_path, &extracted_dir, &lib_dir);
        }
    }

    // Download from GitHub releases
    let url = format!("{RELEASE_BASE_URL}/v{version}/{archive_name}");
    eprintln!("Downloading prebuilt library from {url}...");
    let resp = ureq::get(&url).call()?;
    let mut bytes = Vec::new();
    use std::io::Read;
    resp.into_reader().read_to_end(&mut bytes)?;

    fs::create_dir_all(&extracted_dir)?;
    let bz = BzDecoder::new(bytes.as_slice());
    let mut archive = Archive::new(bz);
    archive.unpack(&extracted_dir)?;

    if lib_dir.is_dir() {
        Ok(lib_dir)
    } else {
        Err(format!(
            "Downloaded archive did not contain a lib/ directory at {}",
            lib_dir.display()
        )
        .into())
    }
}

fn extract_archive(archive_path: &Path, extracted_dir: &Path, lib_dir: &Path) -> Result<PathBuf, DynError> {
    let file = fs::File::open(archive_path)?;
    let bz = BzDecoder::new(file);
    let mut archive = Archive::new(bz);
    fs::create_dir_all(extracted_dir)?;
    archive.unpack(extracted_dir)?;

    if lib_dir.is_dir() {
        Ok(lib_dir.to_path_buf())
    } else {
        Ok(extracted_dir.to_path_buf())
    }
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
        "macos" => {
            println!("cargo:rustc-link-lib=c++");
        }
        "windows" => {}
        _ => {}
    }
}

fn emit_shared_link_directives() {
    println!("cargo:rustc-link-lib=dylib=piper_phonemize_core");
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
