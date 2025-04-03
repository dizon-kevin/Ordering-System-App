plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.devops.ordering_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.devops.ordering_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = System.getenv("CM_BUILD_ID")?.toInt()
        versionName = "1.0.${System.getenv("CM_BUILD_ID")?.toInt()}"
    }

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("CM_KEYSTORE_PATH") ?: rootProject.file("android/app/keystore.jks"))
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: ""
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        }
    }


    buildTypes {
        release {

            signingConfig = signingConfigs.getByName("release")
            )
        }
    }
}

flutter {
    source = "../.."
}