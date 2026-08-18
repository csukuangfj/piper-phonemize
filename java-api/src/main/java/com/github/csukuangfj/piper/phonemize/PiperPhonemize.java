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
        // Check if already extracted
        String cacheKey = "piper-phonemize-espeak-ng-data";
        Path tempDir = new File(System.getProperty("java.io.tmpdir"), cacheKey).toPath();
        if (Files.exists(tempDir.resolve("phontab"))) {
            return tempDir.toString();
        }

        try {
            // Find the JAR file containing this class
            java.net.URL location = PiperPhonemize.class.getProtectionDomain().getCodeSource().getLocation();
            java.net.URI uri = location.toURI();

            if (uri.getScheme().equals("file")) {
                // Running from a JAR file
                File jarFile = new File(uri);
                if (jarFile.isFile()) {
                    // Extract from JAR
                    Files.createDirectories(tempDir);
                    try (java.util.jar.JarFile jar = new java.util.jar.JarFile(jarFile)) {
                        java.util.Enumeration<java.util.jar.JarEntry> entries = jar.entries();
                        while (entries.hasMoreElements()) {
                            java.util.jar.JarEntry entry = entries.nextElement();
                            String name = entry.getName();
                            if (name.startsWith("piper-phonemize/espeak-ng-data/") && !entry.isDirectory()) {
                                String relativePath = name.substring("piper-phonemize/espeak-ng-data/".length());
                                Path target = tempDir.resolve(relativePath);
                                Files.createDirectories(target.getParent());
                                try (InputStream in = jar.getInputStream(entry)) {
                                    Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
                                }
                            }
                        }
                    }
                    return tempDir.toString();
                }
            }

            // Fallback: try to extract from classpath resources
            Files.createDirectories(tempDir);
            String prefix = "piper-phonemize/espeak-ng-data/";
            // Try common file names
            String[] commonFiles = {"phontab", "phondata", "phonindex", "intonations", "intonation"};
            for (String file : commonFiles) {
                try (InputStream in = PiperPhonemize.class.getClassLoader().getResourceAsStream(prefix + file)) {
                    if (in != null) {
                        Files.copy(in, tempDir.resolve(file), StandardCopyOption.REPLACE_EXISTING);
                    }
                }
            }
            return tempDir.toString();
        } catch (Exception e) {
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
