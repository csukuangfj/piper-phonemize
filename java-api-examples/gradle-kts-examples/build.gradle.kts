plugins {
    application
    java
}

application {
    mainClass.set("com.github.csukuangfj.piper.phonemize.example.PhonemizeText")
}

repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

// Auto-detect current OS and architecture
val osName = System.getProperty("os.name").lowercase()
val osArch = System.getProperty("os.arch").lowercase()

val targetNativeClassifier = when {
    osName.contains("mac") || osName.contains("darwin") -> {
        if (osArch == "aarch64" || osArch == "arm64") "osx-aarch64" else "osx-x64"
    }
    osName.contains("linux") -> {
        if (osArch == "aarch64" || osArch == "arm64") "linux-aarch64" else "linux-x64"
    }
    osName.contains("win") -> {
        if (osArch == "aarch64" || osArch == "arm64") "win-arm64" else "win-x64"
    }
    else -> throw GradleException("Unsupported OS: $osName, Arch: $osArch")
}

logger.lifecycle("--> Auto-detected platform native lib: $targetNativeClassifier")

dependencies {
    // 1. JVM core API
    implementation("com.github.csukuangfj.piper-phonemize:piper-phonemize-jvm:jni-SNAPSHOT")

    // 2. Platform native lib (auto-detected)
    implementation("com.github.csukuangfj.piper-phonemize:piper-phonemize-native-lib-$targetNativeClassifier:jni-SNAPSHOT")
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

tasks.jar {
    manifest {
        attributes("Main-Class" to "com.github.csukuangfj.piper.phonemize.example.PhonemizeText")
    }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
}
