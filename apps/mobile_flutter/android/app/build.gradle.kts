plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties from android/key.properties (if present)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.healthtrackme"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.healthtrackme"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only create a release signing config if key properties file exists and has values.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // If a release signing config was created (because key.properties exists) use it,
            // otherwise fall back to the debug signing config so bundle tasks don't try to
            // use an empty release config and produce NPEs.
            signingConfig = if (keystorePropertiesFile.exists() && signingConfigs.findByName("release") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    }
}

flutter {
    source = "../.."
}

// Optional: strict release signing validation.
// If you want the build to fail early when `android/key.properties` is missing,
// run Gradle with -PstrictReleaseSigning=true. This registers a validation task
// that runs before `bundleRelease` and `assembleRelease` and fails with a clear
// message if key.properties is not present.
if (project.hasProperty("strictReleaseSigning")) {
    tasks.register("validateReleaseSigning") {
        doLast {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException("Release signing requested but android/key.properties is missing. Create the file or remove -PstrictReleaseSigning flag.")
            }
        }
    }

    // Make bundle/assemble release tasks depend on our validation when they exist
    listOf("bundleRelease", "assembleRelease").forEach { taskName ->
        tasks.matching { it.name == taskName }.configureEach {
            dependsOn("validateReleaseSigning")
        }
    }
}

