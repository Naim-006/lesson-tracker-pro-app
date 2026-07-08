plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties
val keyProps = mutableMapOf<String, String>()
rootProject.file("key.properties")?.takeIf { it.exists() }?.readLines()?.forEach { line ->
    val trimmed = line.trim()
    if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
        val idx = trimmed.indexOf('=')
        if (idx > 0) {
            keyProps[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim()
        }
    }
}

android {
    namespace = "com.lessontrackerpro.lesson_tracker_pro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lessontrackerpro.lesson_tracker_pro"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProps["keyAlias"] as String
            keyPassword = keyProps["keyPassword"] as String
            storeFile = keyProps["storeFile"]?.let { rootProject.file(it) }
            storePassword = keyProps["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
