package com.github.csukuangfj.piper.phonemize;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;

/*
# We support the following loading methods

## Method 1 Specify the property piper_phonemize.native.path

We assume the path contains the library piper-phonemize-jni.

java \
 -Dpiper_phonemize.native.path=/path/to/lib \
 -cp piper-phonemize-jvm.jar \
 xxx.java

## Method 2 Specify the native jar library

java \
 -cp piper-phonemize-jvm.jar:/path/to/piper-phonemize-native-lib-osx-x64.jar \
 xxx.java

Note that you need to replace  : in -cp with ; on windows.

## Method 3 Specify the property java.library.path

We assume the path contains the library piper-phonemize-jni.

java \
 -Djava.library.path=/path/to/lib \
 -cp piper-phonemize-jvm.jar \
 xxx.java

 */

public class LibraryUtils {
    private static final String NATIVE_PATH_PROP = "piper_phonemize.native.path";
    private static final String LIB_NAME = "piper-phonemize-jni";

    private static boolean debug = false;

    public static void enableDebug() {
        debug = true;
    }

    public static void disableDebug() {
        debug = false;
    }

    public static void load() {
        // 1. Try to load from external directory specified by -Dpiper_phonemize.native.path
        if (loadFromNativePath()) {
            return;
        }

        // 2. Load from resources contained in some jar file
        if (!isAndroid()) {
            try {
                if (loadFromResourceInJar()) {
                    return;
                }
            } catch (IOException e) {
                // pass
            }
        }

        // 3. fallback to -Djava.library.path
        System.loadLibrary(LIB_NAME);
    }

    private static boolean loadFromNativePath() {
        String libFileName = System.mapLibraryName(LIB_NAME);
        String nativePath = System.getProperty(NATIVE_PATH_PROP);

        if (nativePath != null) {
            File nativeDir = new File(nativePath);
            File libInDir = new File(nativeDir, libFileName);
            if (nativeDir.isDirectory() && libInDir.exists()) {
                if (debug) {
                    System.out.printf("Loading from: %s\n", libInDir.getAbsolutePath());
                }
                System.load(libInDir.getAbsolutePath());
                return true;
            }
        }

        return false;
    }

    private static boolean loadFromResourceInJar() throws IOException {
        String libFileName = System.mapLibraryName(LIB_NAME);
        String resourcePath = "piper-phonemize/native/" + getOsArch() + '/' + libFileName;

        Path tempDirectory = null;
        try {
            if (!resourceExists(resourcePath)) {
                if (debug) {
                    System.out.printf("%s does not exist\n", resourcePath);
                }
                return false;
            }

            tempDirectory = Files.createTempDirectory("piper-phonemize-java");

            File tempFile = tempDirectory.resolve(libFileName).toFile();
            extractResource(resourcePath, tempFile);
            System.load(tempFile.getAbsolutePath());
        } finally {
            if (tempDirectory != null) {
                cleanUpTempDir(tempDirectory.toFile());
            }
        }

        return true;
    }

    private static String getOsArch() {
        String os = System.getProperty("os.name", "generic").toLowerCase(Locale.ENGLISH);
        String detectedOS;
        if (os.contains("mac") || os.contains("darwin")) {
            detectedOS = "osx";
        } else if (os.contains("win")) {
            detectedOS = "win";
        } else if (os.contains("nux")) {
            detectedOS = "linux";
        } else {
            throw new IllegalStateException("Unsupported os:" + os);
        }

        String detectedArch;
        String arch = System.getProperty("os.arch", "generic").toLowerCase(Locale.ENGLISH);
        if (arch.startsWith("amd64") || arch.startsWith("x86_64")) {
            detectedArch = "x64";
        } else if (arch.startsWith("x86")) {
            detectedArch = "x86";
        } else if (arch.startsWith("aarch64") || arch.startsWith("arm64")) {
            if (detectedOS.equals("win")) {
                detectedArch = "arm64";
            } else {
                detectedArch = "aarch64";
            }
        } else if (arch.startsWith("arm")) {
            detectedArch = "arm";
        } else {
            throw new IllegalStateException("Unsupported arch:" + arch);
        }

        return detectedOS + '-' + detectedArch;
    }

    private static void extractResource(String resourcePath, File destination) {
        if (debug) {
            System.out.printf("Extracting %s to %s\n", resourcePath, destination.getAbsolutePath());
        }
        try (InputStream in = LibraryUtils.class.getClassLoader().getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new RuntimeException("Resource not found: " + resourcePath);
            }
            Files.copy(in, destination.toPath(), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Failed to extract " + resourcePath, e);
        }
    }

    private static boolean resourceExists(String path) {
        return LibraryUtils.class.getClassLoader().getResource(path) != null;
    }

    private static void cleanUpTempDir(File dir) {
        if (!dir.exists()) return;
        File[] files = dir.listFiles();
        if (files != null) {
            for (File f : files) {
                f.deleteOnExit();
            }
        }
        dir.deleteOnExit();
    }

    static boolean isAndroid() {
        String vmName = System.getProperty("java.vm.name", "").toLowerCase(Locale.ROOT);
        String specVendor = System.getProperty("java.specification.vendor", "");
        return vmName.contains("dalvik") || vmName.contains("art") ||
               specVendor.equals("The Android Project");
    }
}
