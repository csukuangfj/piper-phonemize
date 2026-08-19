# Design Notes: .NET / NuGet Packaging

## Package Architecture

Two-tier NuGet package structure (same pattern as sherpa-onnx):

### Common Package: `com.github.csukuangfj.piper.phonemize`

Contains:
- C# binding source code (P/Invoke wrappers for the C API in `src/c-api.h`)
- `espeak-ng-data` as content files (platform-independent data)
- A `.targets` file that copies espeak-ng-data to the output directory at build time
- References all platform runtime packages as transitive dependencies

Users only reference this package. The runtime packages are pulled in automatically.

### Platform Runtime Packages: `com.github.csukuangfj.piper.phonemize.runtime.{RID}`

Each contains ONLY the native shared library (`libpiper_phonemize_core.so`/`.dylib`/`.dll`).
Placed at `runtimes/{rid}/native/` inside the NuGet package. The .NET runtime
automatically loads the correct native library based on the current RID.

Supported RIDs: `linux-x64`, `linux-arm64`, `android-arm64`, `android-x64`,
`osx-x64`, `osx-arm64`, `win-x64`, `win-arm64`.

## Why a .targets File?

NuGet `contentFiles` with `buildAction="None"` are NOT automatically copied to
the output directory — they are only available in the package cache. A `.targets`
file shipped inside the package (`build/com.github.csukuangfj.piper.phonemize.targets`)
is automatically imported by MSBuild when the package is installed, and runs a
`CopyEspeakNgData` target after build to copy the data files from the package
cache to `$(OutputPath)espeak-ng-data/`.

## C# API Design

Follows the same pattern as sherpa-onnx:

- `Dll.cs` — P/Invoke library name constant (`piper_phonemize_core`)
- `PiperPhonemizeApi.cs` — Main API class wrapping C API functions from `c-api.h`
- `PhonemizeResult.cs` — `IDisposable` wrapper for the opaque result handle

The native library name is `piper_phonemize_core` (not `piper-phonemize-jni` —
JNI is for Java/Kotlin; .NET uses the C API directly via P/Invoke).

## Build Process

`run.sh` orchestrates the build:

1. `generate.py` reads `.csproj.in` templates (Jinja2) and generates `.csproj`
   files for each RID and the common package
2. Native libs for each RID are expected in `/tmp/dotnet/{rid}/` (provided by CI)
3. `dotnet pack` creates `.nupkg` files in `/tmp/dotnet/packages/`

`generate.py` reads the version from `CMakeLists.txt` (skipping commented-out lines).

## CI Workflows

- `dot-net.yaml` — Builds native libs for all platforms (matrix strategy),
  packs NuGet packages, uploads as artifacts, pushes to nuget.org via OIDC
  (Trusted Publishing, no API key needed)
- `test-dot-net.yaml` — Two jobs:
  - `test-local`: builds native lib + NuGet from source, tests with local packages
  - `test-published`: tests with packages from nuget.org on all 6 platforms

## Template Files

Both `.csproj.in` files use Jinja2 `{{ variable }}` syntax:
- `{{ version }}` — from CMakeLists.txt
- `{{ dotnet_rid }}` — runtime identifier (runtime package only)
- `{{ libs }}` — path to native library file (runtime package only)
- `{{ packages_dir }}` — local packages directory for `RestoreSources` (common package only)
