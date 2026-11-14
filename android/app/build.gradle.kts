import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

val envStoreFile = System.getenv("FTH_UPLOAD_STORE_FILE")
    ?: System.getenv("FTH_KEYSTORE_FILE")
val envStorePassword = System.getenv("FTH_UPLOAD_STORE_PASSWORD")
    ?: System.getenv("FTH_KEYSTORE_PASSWORD")
val envKeyAlias = System.getenv("FTH_UPLOAD_KEY_ALIAS")
    ?: System.getenv("FTH_KEY_ALIAS")
val envKeyPassword = System.getenv("FTH_UPLOAD_KEY_PASSWORD")
    ?: System.getenv("FTH_KEY_PASSWORD")

val releaseStoreFilePath =
    (keystoreProperties.getProperty("storeFile") ?: envStoreFile)?.trim().orEmpty()
val releaseStorePassword =
    (keystoreProperties.getProperty("storePassword") ?: envStorePassword).orEmpty()
val releaseKeyAlias =
    (keystoreProperties.getProperty("keyAlias") ?: envKeyAlias)?.trim().orEmpty()
val releaseKeyPassword =
    (keystoreProperties.getProperty("keyPassword") ?: envKeyPassword).orEmpty()

val hasReleaseKeystore = releaseStoreFilePath.isNotEmpty() &&
    releaseStorePassword.isNotEmpty() &&
    releaseKeyAlias.isNotEmpty() &&
    releaseKeyPassword.isNotEmpty() &&
    rootProject.file(releaseStoreFilePath).exists()

if (!hasReleaseKeystore && project.hasProperty("requireReleaseSigning")) {
    throw GradleException(
        "Play Store release signing requires android/key.properties or FTH_UPLOAD_* environment variables. Debug keys are prohibited."
    )
}

android {
    namespace = "com.familytransithome.family_transit_home"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.familytransithome.family_transit_home"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFilePath)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Production Play Store releases must never use Android Debug keys.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
