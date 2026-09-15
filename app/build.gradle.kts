plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // Flutter Gradle Plugin must be applied after
    // the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
        import java.io.FileInputStream

// -----------------------------------------------------------------------------
// RELEASE KEYSTORE
// -----------------------------------------------------------------------------

val keystorePropertiesFile =
    rootProject.file("key.properties")

val keystoreProperties =
    Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "site.qify.qify_authenticator"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "site.qify.qify_authenticator"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // -------------------------------------------------------------------------
    // RELEASE SIGNING CONFIG
    // -------------------------------------------------------------------------

    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties["keyAlias"] as String

            keyPassword =
                keystoreProperties["keyPassword"] as String

            storeFile =
                file(
                    keystoreProperties["storeFile"] as String
                )

            storePassword =
                keystoreProperties["storePassword"] as String
        }
    }

    // -------------------------------------------------------------------------
    // BUILD TYPES
    // -------------------------------------------------------------------------

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}