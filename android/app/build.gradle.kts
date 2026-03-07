plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.github.triplet.play")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val signingProps = Properties()
val signingFile = rootProject.file("../key.properties")
if (signingFile.exists()) {
    signingFile.inputStream().use(signingProps::load)
}

fun signingValue(key: String): String? {
    val fromFile = signingProps.getProperty(key)?.trim()
    if (!fromFile.isNullOrEmpty()) return fromFile
    return System.getenv(key)?.trim()?.takeIf { it.isNotEmpty() }
}

android {
    namespace = "com.forroemmilao.radiofem"
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
        applicationId = "com.forroemmilao.radiofem"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = signingValue("RELEASE_STORE_FILE")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file("../$storeFilePath")
            }
            storePassword = signingValue("RELEASE_STORE_PASSWORD")
            keyAlias = signingValue("RELEASE_KEY_ALIAS")
            keyPassword = signingValue("RELEASE_KEY_PASSWORD")
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

play {
    serviceAccountCredentials.set(rootProject.file("../play-account.json"))
    track.set("internal")
    defaultToAppBundles.set(true)
}
