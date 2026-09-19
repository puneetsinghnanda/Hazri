plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "app.hazri"
    // Google Play requires targetSdk 36 for new apps and updates from 31 Aug 2026.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs the desugared java.time APIs on
        // older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "app.hazri"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The app ships Punjabi, Hindi and English only; keeping the resource
        // set to those three trims the bundled AndroidX translations.
        resourceConfigurations += setOf("en", "pa", "hi")
    }

    buildTypes {
        release {
            // The test build is signed with the debug key so it installs
            // straight from a download. A release to Play uses Play App
            // Signing with an upload key kept outside the repository.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            // Resource shrinking is OFF, and must stay off. audio_service
            // resolves every icon it puts in the media notification by name at
            // runtime -- getResources().getIdentifier("ic_notification", ...)
            // and the same for its play/pause/skip icons. Nothing in the code
            // or the XML refers to them, so the shrinker takes them out, the
            // small icon resolves to 0, and startForeground() throws "invalid
            // notification". The recitation keeps playing, because that is
            // just_audio and not the service, but there is no notification and
            // so no lock-screen controls -- which is exactly what happened.
            // The saving on a 22 MB app is a few hundred kilobytes.
            // Measured, not assumed: building this app with shrinking on and
            // off and reading both resource tables, all seven of those icons
            // are simply absent from the shrunk one -- no entry at all, not
            // even a placeholder. Turning it off costs about 220 KB in the
            // APK. Left settable so that comparison can be run again; CI
            // asserts the icons are in whatever gets built.
            isShrinkResources = project.findProperty("hazri.shrinkResources") == "true"
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
