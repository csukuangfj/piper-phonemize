#!/usr/bin/env python3
# Copyright (c) 2026  Xiaomi Corporation
#
# Generate .csproj files from Jinja2 templates for NuGet packaging.

import os
import re
import shutil
from pathlib import Path

import jinja2

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent

# RID -> (dotnet_rid, lib_filename)
PLATFORMS = {
    "linux-x64": ("linux-x64", "libpiper_phonemize_core.so"),
    "linux-arm64": ("linux-arm64", "libpiper_phonemize_core.so"),
    "android-arm64": ("android-arm64", "libpiper_phonemize_core.so"),
    "android-x64": ("android-x64", "libpiper_phonemize_core.so"),
    "osx-x64": ("osx-x64", "libpiper_phonemize_core.dylib"),
    "osx-arm64": ("osx-arm64", "libpiper_phonemize_core.dylib"),
    "win-x64": ("win-x64", "piper_phonemize_core.dll"),
    "win-arm64": ("win-arm64", "piper_phonemize_core.dll"),
}


def get_version():
    cmake_file = PROJECT_DIR / "CMakeLists.txt"
    with open(cmake_file) as f:
        content = f.read()
    version = re.search(r"set\(PIPER_PHONEMIZE_VERSION (.*)\)", content).group(1)
    return version.strip('"')


def generate(src_dir: str, output_dir: str):
    src_dir = Path(src_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    version = get_version()
    print(f"Version: {version}")

    environment = jinja2.Environment()

    # Read templates
    with open(SCRIPT_DIR / "PiperPhonemize.Runtime.csproj.in") as f:
        runtime_template = environment.from_string(f.read())

    with open(SCRIPT_DIR / "PiperPhonemize.csproj.in") as f:
        common_template = environment.from_string(f.read())

    # Generate per-RID runtime packages
    for rid, (dotnet_rid, lib_filename) in PLATFORMS.items():
        rid_dir = output_dir / rid
        rid_dir.mkdir(parents=True, exist_ok=True)

        lib_path = src_dir / rid / lib_filename
        if not lib_path.exists():
            print(f"  WARNING: {lib_filename} not found for {rid}, skipping")
            continue

        # Copy native lib to rid directory (skip if same file)
        dst = rid_dir / lib_filename
        if lib_path.resolve() != dst.resolve():
            shutil.copy2(lib_path, dst)

        libs_str = str(rid_dir / lib_filename)
        d = {"version": version, "dotnet_rid": dotnet_rid, "libs": libs_str}
        s = runtime_template.render(**d)

        with open(rid_dir / "PiperPhonemize.Runtime.csproj", "w") as f:
            f.write(s)

        print(f"  Generated runtime csproj for {rid}")

    # Generate common (metapackage) package
    common_dir = output_dir / "all"
    common_dir.mkdir(parents=True, exist_ok=True)

    # Copy C# source files
    for src_file in ["Dll.cs", "PiperPhonemizeApi.cs", "PhonemizeResult.cs"]:
        shutil.copy2(SCRIPT_DIR / src_file, common_dir / src_file)

    # Copy espeak-ng-data
    espeak_src = PROJECT_DIR / "swift-api-examples" / "espeak-ng-data"
    espeak_dst = common_dir / "espeak-ng-data"
    if espeak_src.is_dir() and not espeak_dst.exists():
        shutil.copytree(espeak_src, espeak_dst)

    packages_dir = str(output_dir / "packages")
    d = {"version": version, "packages_dir": packages_dir}
    s = common_template.render(**d)

    with open(common_dir / "PiperPhonemize.csproj", "w") as f:
        f.write(s)

    print(f"Generated common package csproj in {common_dir}")


def main():
    import sys

    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <src_dir> <output_dir>")
        print("")
        print("  src_dir:   directory containing per-RID native libs")
        print("             e.g. /tmp/dotnet with linux-x64/, osx-arm64/, etc.")
        print("  output_dir: where to write generated csproj files")
        sys.exit(1)

    src_dir = sys.argv[1]
    output_dir = sys.argv[2]
    generate(src_dir, output_dir)


if __name__ == "__main__":
    main()
