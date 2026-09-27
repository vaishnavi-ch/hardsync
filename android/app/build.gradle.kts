import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hardsync.mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.hardsync.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val signingProperties = Properties()
    val signingPropertiesFile = rootProject.file("key.properties")
    if (signingPropertiesFile.exists()) {
        signingPropertiesFile.inputStream().use(signingProperties::load)
    }

    signingConfigs {
        create("release") {
            val keystorePath = signingProperties.getProperty("storeFile")
            if (!keystorePath.isNullOrBlank()) {
                storeFile = rootProject.file(keystorePath)
            }
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
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

// video_player_android pulls in the full androidx.media3 exoplayer suite,
// including protocol modules (SmoothStreaming, RTSP, etc.) this app never
// uses for its simple recorded-webm playback. Excluding them avoids
// depending on artifacts that intermittently fail to resolve through
// network-inspecting proxies (e.g. antivirus TLS interception).
configurations.all {
    exclude(group = "androidx.media3", module = "media3-exoplayer-smoothstreaming")
    exclude(group = "androidx.media3", module = "media3-exoplayer-rtsp")
    exclude(group = "androidx.media3", module = "media3-exoplayer-ima")
}
