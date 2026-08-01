plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadStoreFile = System.getenv("AURA_SHIFT_UPLOAD_STORE_FILE")
val uploadStorePassword = System.getenv("AURA_SHIFT_UPLOAD_STORE_PASSWORD")
val uploadKeyPassword = System.getenv("AURA_SHIFT_UPLOAD_KEY_PASSWORD")
val uploadKeyAlias = System.getenv("AURA_SHIFT_UPLOAD_KEY_ALIAS") ?: "aura-shift-upload"
val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val productionAdMobAppId = "ca-app-pub-1879801690271355~3301040623"
val playGamesProjectId =
    System.getenv("PGS_GAME_PROJECT_ID")?.takeIf { it.isNotBlank() } ?: "293539263998"
val hasUploadSigning = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyPassword,
).all { !it.isNullOrBlank() }

if (
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) } &&
    !hasUploadSigning
) {
    throw GradleException(
        "Release signing is not configured. Set the AURA_SHIFT_UPLOAD_* environment variables.",
    )
}

android {
    namespace = "com.otaciliomaia.aurashiftsixseven"
    compileSdk = flutter.compileSdkVersion
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.otaciliomaia.aurashiftsixseven"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Debug/profile builds use Google's official test inventory.
        manifestPlaceholders["ADMOB_APP_ID"] = testAdMobAppId
        resValue("string", "game_services_project_id", playGamesProjectId)
    }

    signingConfigs {
        create("release") {
            if (hasUploadSigning) {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles("proguard-rules.pro")
            // Release bundles always keep this app's ID so UMP resolves the
            // privacy message configured for Aura Shift. Closed-test builds
            // opt into Google's demo rewarded unit in Dart only.
            manifestPlaceholders["ADMOB_APP_ID"] = productionAdMobAppId
        }
    }
}

dependencies {
    implementation("com.google.android.play:age-signals:0.0.3")
    implementation("com.google.android.gms:play-services-games-v2:21.0.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
