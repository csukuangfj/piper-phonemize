1. Now please follow ../sherpa-onnx to add Go API for this repo
2. You need to first look at ../sherpa-onnx/scripts/go
   I have created the following four projects,
     - https://github.com/csukuangfj/piper-phonemize-go
     - https://github.com/csukuangfj/piper-phonemize-go-linux
     - https://github.com/csukuangfj/piper-phonemize-go-windows
     - https://github.com/csukuangfj/piper-phonemize-go-macos
3. You should also have a look at ../sherpa-onnx/.github/workflows/release-go.yaml
   Note that instead of downloading wheels, you can build this project from source
   to get needed libraries. You can use shared lib
4. please help to add Go API and release the Go packages.
5. Remember to follow what sherpa-onnx does, e.g, split the package into linux, macos, and windows, and
   use piper-phonemize-go to combine them.
