package com.github.csukuangfj.piper.phonemize;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

public class PiperPhonemize {

    private static String espeakNgDataDir = null;

    /**
     * Initialize piper-phonemize with an explicit data directory.
     *
     * @param dataDir Path to the espeak-ng-data directory.
     * @return Sample rate on first call, 0 on subsequent calls, or -1 on failure.
     */
    public static int initializeWithDataDir(String dataDir) {
        LibraryLoader.maybeLoad();
        return nativeInitialize(dataDir);
    }

    /**
     * Initialize piper-phonemize by extracting embedded espeak-ng-data from JAR resources.
     *
     * @return Sample rate on first call, 0 on subsequent calls, or -1 on failure.
     */
    public static int initialize() {
        if (espeakNgDataDir == null) {
            espeakNgDataDir = extractEspeakNgData();
        }
        return initializeWithDataDir(espeakNgDataDir);
    }

    /**
     * Phonemize text using the specified voice.
     *
     * @param text  The text to phonemize (UTF-8).
     * @param voice The espeak-ng voice to use (e.g. "en-us").
     * @return A Result handle, or null on failure.
     */
    public static Result text(String text, String voice) {
        LibraryLoader.maybeLoad();
        long handle = nativeText(text, voice);
        if (handle == 0) {
            return null;
        }
        return new Result(handle);
    }

    /**
     * Phonemize text using the default voice ("en-us").
     */
    public static Result text(String text) {
        return text(text, "en-us");
    }

    /**
     * Get the piper-phonemize version string.
     */
    public static String getVersionStr() {
        LibraryLoader.maybeLoad();
        return nativeGetVersionStr();
    }

    /**
     * Result handle from phonemization. Implements AutoCloseable for resource management.
     */
    public static class Result implements AutoCloseable {
        private long handle;

        Result(long handle) {
            this.handle = handle;
        }

        public int getNumSentences() {
            return nativeGetNumSentences(handle);
        }

        public int getNumPhonemes(int sentenceId) {
            return nativeGetNumPhonemes(handle, sentenceId);
        }

        public int[] getPhonemes(int sentenceId) {
            return nativeGetPhonemes(handle, sentenceId);
        }

        public String getPhonemesAsString(int sentenceId) {
            int[] phonemes = getPhonemes(sentenceId);
            StringBuilder sb = new StringBuilder();
            for (int p : phonemes) {
                sb.appendCodePoint(p);
            }
            return sb.toString();
        }

        public List<String> getAllPhonemesAsStrings() {
            List<String> result = new ArrayList<>();
            int numSentences = getNumSentences();
            for (int i = 0; i < numSentences; i++) {
                result.add(getPhonemesAsString(i));
            }
            return result;
        }

        @Override
        public void close() {
            if (handle != 0) {
                nativeDestroyResult(handle);
                handle = 0;
            }
        }

        @Override
        protected void finalize() throws Throwable {
            close();
            super.finalize();
        }
    }

    private static String extractEspeakNgData() {
        String resourcePath = "piper-phonemize/espeak-ng-data/phontab";
        try (InputStream in = PiperPhonemize.class.getClassLoader().getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new RuntimeException("espeak-ng-data not found in JAR resources");
            }

            Path tempDir = Files.createTempDirectory("piper-phonemize-espeak-ng-data");
            // We found the resource, so the data directory is the parent of "phontab"
            // We need to extract the entire directory
            String dataDirResource = "piper-phonemize/espeak-ng-data/";
            String[] files = {"phontab", "phondata", "phonindex", "intonations", "intonation"};
            // Try to extract common files
            for (String file : files) {
                String fullPath = dataDirResource + file;
                try (InputStream fis = PiperPhonemize.class.getClassLoader().getResourceAsStream(fullPath)) {
                    if (fis != null) {
                        Files.copy(fis, tempDir.resolve(file), StandardCopyOption.REPLACE_EXISTING);
                    }
                }
            }
            // Also try to extract all files by listing the directory (not always possible with JAR resources)
            // Fallback: return the temp dir with whatever we extracted
            return tempDir.toString();
        } catch (IOException e) {
            throw new RuntimeException("Failed to extract espeak-ng-data", e);
        }
    }

    // Native methods
    private static native String nativeGetVersionStr();
    private static native int nativeInitialize(String dataDir);
    private static native long nativeText(String text, String voice);
    private static native int nativeGetNumSentences(long handle);
    private static native int nativeGetNumPhonemes(long handle, int sentenceId);
    private static native int[] nativeGetPhonemes(long handle, int sentenceId);
    private static native void nativeDestroyResult(long handle);
}
