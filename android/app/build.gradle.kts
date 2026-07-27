import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "de.unitune.unitune"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.unitune.unitune"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Default launcher label. Overridden per build type below so the dev
        // build is distinguishable in the launcher and the share sheet.
        manifestPlaceholders["appLabel"] = "UniTune"
        manifestPlaceholders["admobAppId"] = "ca-app-pub-8547021258440704~3406297771"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
    }

    buildTypes {
        debug {
            // Distinct application id so a debug/test build installs ALONGSIDE
            // an installed release build instead of trying to replace it.
            //
            // Both are debug-signed but with keystores generated per machine
            // (and per CI runner), so an in-place update would be rejected with
            // INSTALL_FAILED_UPDATE_INCOMPATIBLE and force an uninstall — which
            // wipes history, playlists and settings, since all app state lives
            // in SharedPreferences and there is no export.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "UniTune Dev"

            // Google's public test app id. The `.dev` application id is not
            // registered with AdMob, so pointing it at the production app id
            // would only produce no-fills and risk invalid-traffic flags.
            // Pair with --dart-define=USE_TEST_ADS=true for the ad units.
            manifestPlaceholders["admobAppId"] =
                "ca-app-pub-3940256099942544~3347511713"
        }

        release {
            // Sign with release keystore if key.properties exists, otherwise use debug keys
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
