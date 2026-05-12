import groovy.json.JsonSlurper
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.chargego"
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
        applicationId = "com.example.chargego"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = project.googleMapsApiKey()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

fun Project.googleMapsApiKey(): String {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }

    val configuredKey =
        localProperties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: providers.gradleProperty("GOOGLE_MAPS_API_KEY").orNull
            ?: System.getenv("GOOGLE_MAPS_API_KEY")

    if (!configuredKey.isNullOrBlank()) {
        return configuredKey
    }

    val googleServicesFile = file("google-services.json")
    if (!googleServicesFile.exists()) {
        return ""
    }

    val root = JsonSlurper().parse(googleServicesFile) as Map<*, *>
    val clients = root["client"] as? List<*> ?: return ""
    val firstClient = clients.firstOrNull() as? Map<*, *> ?: return ""
    val apiKeys = firstClient["api_key"] as? List<*> ?: return ""
    val firstApiKey = apiKeys.firstOrNull() as? Map<*, *> ?: return ""
    return firstApiKey["current_key"] as? String ?: ""
}
