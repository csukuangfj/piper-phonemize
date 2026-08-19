#!/usr/bin/env python3
# Copyright (c) 2026  Xiaomi Corporation
#
# Generate .csproj files from Jinja2 templates for NuGet packaging.

import os
import sys
from string import Template

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

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


def generate(version: str, output_dir: str):
    os.makedirs(output_dir, exist_ok=True)

    # Read templates
    with open(os.path.join(SCRIPT_DIR, "PiperPhonemize.csproj.in")) as f:
        common_template = Template(f.read())

    with open(os.path.join(SCRIPT_DIR, "PiperPhonemize.Runtime.csproj.in")) as f:
        runtime_template = Template(f.read())

    # Generate common package csproj
    common_csproj = common_template.substitute(version=version)
    common_dir = os.path.join(output_dir, "all")
    os.makedirs(common_dir, exist_ok=True)

    # Copy C# source files
    for src_file in ["Dll.cs", "PiperPhonemizeApi.cs", "PhonemizeResult.cs"]:
        src_path = os.path.join(SCRIPT_DIR, src_file)
        dst_path = os.path.join(common_dir, src_file)
        with open(src_path, "r") as f_in:
            with open(dst_path, "w") as f_out:
                f_out.write(f_in.read())

    # Copy espeak-ng-data
    espeak_src = os.path.join(SCRIPT_DIR, "..", "..", "swift-api-examples", "espeak-ng-data")
    espeak_dst = os.path.join(common_dir, "espeak-ng-data")
    if os.path.isdir(espeak_src) and not os.path.isdir(espeak_dst):
        import shutil
        shutil.copytree(espeak_src, espeak_dst)

    with open(os.path.join(common_dir, "PiperPhonemize.csproj"), "w") as f:
        f.write(common_csproj)

    print(f"Generated common package csproj in {common_dir}")

    # Generate per-RID runtime package csproj
    for rid, (dotnet_rid, lib_filename) in PLATFORMS.items():
        rid_dir = os.path.join(output_dir, rid)
        os.makedirs(rid_dir, exist_ok=True)

        # Find the native lib
        lib_path = os.path.join(rid_dir, lib_filename)
        if not os.path.exists(lib_path):
            # Try relative to output_dir parent
            lib_path = os.path.join(output_dir, "..", rid, lib_filename)

        if not os.path.exists(lib_path):
            print(f"  WARNING: {lib_filename} not found for {rid}, skipping")
            continue

        csproj = runtime_template.substitute(
            version=version,
            dotnet_rid=dotnet_rid,
            libs=lib_filename,
        )

        with open(os.path.join(rid_dir, "PiperPhonemize.Runtime.csproj"), "w") as f:
            f.write(csproj)

        print(f"  Generated runtime csproj for {rid}")


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <version> <output_dir>")
        sys.exit(1)

    version = sys.argv[1]
    output_dir = sys.argv[2]
    generate(version, output_dir)


if __name__ == "__main__":
    main()
