plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.github.triplet.play")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.util.Base64
import com.github.triplet.gradle.androidpublisher.ReleaseStatus
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

data class PubspecVersion(
    val name: String,
    val code: Int,
)

val signingProps = Properties()
val signingFile = rootProject.file("../key.properties")
if (signingFile.exists()) {
    signingFile.inputStream().use(signingProps::load)
}

val localProps = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use(localProps::load)
}

fun signingValue(key: String): String? {
    val fromFile = signingProps.getProperty(key)?.trim()
    if (!fromFile.isNullOrEmpty()) return fromFile
    return System.getenv(key)?.trim()?.takeIf { it.isNotEmpty() }
}

fun localOrEnvValue(localKey: String, envKey: String): String? {
    val fromSigningFileLocal = signingProps.getProperty(localKey)?.trim()
    if (!fromSigningFileLocal.isNullOrEmpty()) return fromSigningFileLocal
    val fromSigningFileEnv = signingProps.getProperty(envKey)?.trim()
    if (!fromSigningFileEnv.isNullOrEmpty()) return fromSigningFileEnv
    val fromLocal = localProps.getProperty(localKey)?.trim()
    if (!fromLocal.isNullOrEmpty()) return fromLocal
    return System.getenv(envKey)?.trim()?.takeIf { it.isNotEmpty() }
}

fun encodeDartDefine(value: String): String =
    Base64.getEncoder().encodeToString(value.toByteArray(Charsets.UTF_8))

fun loadPubspecVersion(): PubspecVersion? {
    val pubspecFile = rootProject.file("../pubspec.yaml")
    if (!pubspecFile.exists()) {
        return null
    }

    val match = Regex("""(?m)^version:\s*([^\+\s]+)\+(\d+)\s*$""")
        .find(pubspecFile.readText())
        ?: return null

    return PubspecVersion(
        name = match.groupValues[1],
        code = match.groupValues[2].toInt(),
    )
}

val analyticsApiKey = localOrEnvValue(
    "radiofem.analyticsApiKey",
    "RADIO_FEM_ANALYTICS_API_KEY",
)
val pubspecVersion = loadPubspecVersion()
val appVersionName =
    localOrEnvValue("radiofem.versionName", "RADIO_FEM_VERSION_NAME")
        ?: pubspecVersion?.name
        ?: flutter.versionName
val appVersionCode =
    localOrEnvValue("radiofem.versionCode", "RADIO_FEM_VERSION_CODE")
        ?.toIntOrNull()
        ?: pubspecVersion?.code
        ?: flutter.versionCode
val playTrack =
    localOrEnvValue("radiofem.playTrack", "RADIO_FEM_PLAY_TRACK")
        ?: "beta"

if (!analyticsApiKey.isNullOrBlank() && !project.hasProperty("dart-defines")) {
    extensions.extraProperties["dart-defines"] = encodeDartDefine(
        "RADIO_FEM_ANALYTICS_API_KEY=$analyticsApiKey"
    )
}

android {
    namespace = "com.forroemmilao.radiofem"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    packaging {
        jniLibs {
            keepDebugSymbols += "**/*.so"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.forroemmilao.radiofem"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
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

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

play {
    serviceAccountCredentials.set(rootProject.file("../play-account.json"))
    track.set(playTrack)
    releaseStatus.set(ReleaseStatus.COMPLETED)
    defaultToAppBundles.set(true)
}
