// android/app/build.gradle.kts
import java.util.Properties

val localProps = Properties().apply {
    load(rootProject.file("local.properties").inputStream())
}
val flutterVersionName = localProps.getProperty("flutter.versionName") ?: "0.0.0"
val flutterVersionCode = (localProps.getProperty("flutter.versionCode") ?: "1").toInt()

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rfivesix.hypertrack"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
         applicationId = "com.rfivesix.hypertrack"
        versionName = flutterVersionName
        versionCode = flutterVersionCode

        minSdk = 26
        targetSdk = 36      // optional; you can set it or let Flutter handle it
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") { }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "1.8" }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.health.connect:connect-client:1.1.0-rc02")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
