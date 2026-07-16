# espeak-ng-data for WASM browser build

This directory should contain the `espeak-ng-data` folder.

## How to populate

Download and extract espeak-ng-data:

```bash
cd /path/to/piper-phonemize/wasm/browser/assets
curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
tar xvf espeak-ng-data.tar.bz2
rm espeak-ng-data.tar.bz2
```

## Expected structure

After extraction, you should have:
```
assets/
└── espeak-ng-data/
    ├── phontab
    ├── phondata
    ├── phonindex
    ├── en_dict
    ├── de_dict
    ├── lang/
    └── ...
```
