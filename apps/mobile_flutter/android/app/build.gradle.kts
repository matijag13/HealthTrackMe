plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.appdistribution")
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

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "healthtrackme.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "healthtrackme123"
            keyAlias = System.getenv("KEY_ALIAS") ?: "healthtrackme"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "healthtrackme123"
        }
    }

    defaultConfig {
        applicationId = "com.example.healthtrackme"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            firebaseAppDistribution {
                appId = "1:46567361839:android:6bfd89275b8329a82ae5da"
                releaseNotes = "Latest build from develop branch"
                groups = "testers"
            }
        }
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
}

flutter {
    source = "../.."
}
