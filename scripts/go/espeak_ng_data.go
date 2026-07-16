package piper_phonemize

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"
	"sync"
)

//go:embed espeak-ng-data
var espeakNgData embed.FS

var (
	extractedDir string
	extractOnce  sync.Once
	extractErr   error
)

// getEspeakNgDataDir extracts the embedded espeak-ng-data to a temporary
// directory and returns its path. The extraction happens only once per
// process lifetime.
func getEspeakNgDataDir() (string, error) {
	extractOnce.Do(func() {
		tmpDir, err := os.MkdirTemp("", "espeak-ng-data-*")
		if err != nil {
			extractErr = err
			return
		}

		err = fs.WalkDir(espeakNgData, "espeak-ng-data", func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			target := filepath.Join(tmpDir, path)
			if d.IsDir() {
				return os.MkdirAll(target, 0o755)
			}
			data, err := espeakNgData.ReadFile(path)
			if err != nil {
				return err
			}
			return os.WriteFile(target, data, 0o644)
		})
		if err != nil {
			os.RemoveAll(tmpDir)
			extractErr = err
			return
		}

		extractedDir = filepath.Join(tmpDir, "espeak-ng-data")
	})
	return extractedDir, extractErr
}

// Initialize initializes espeak-ng. This must be called before Phonemize.
// It is safe to call multiple times; only the first call takes effect.
//
// If dataDir is empty, the embedded espeak-ng-data is extracted to a
// temporary directory and used. Otherwise, dataDir must be the path to an
// espeak-ng-data directory on disk.
//
// Returns the sample rate (22050) on success, or -1 on failure.
func Initialize(dataDir string) int32 {
	if dataDir == "" {
		var err error
		dataDir, err = getEspeakNgDataDir()
		if err != nil {
			return -1
		}
	}
	return _platformInitialize(dataDir)
}
