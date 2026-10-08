import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// The release signing key, when there is one.
//
// `android/key.properties` is never in git (see `android/.gitignore`); CI
// writes it from secrets, and a developer signing locally writes their own.
// When it is absent the build falls back to the debug key, so a fork, a pull
// request from one, and a fresh clone all still compile — which is most of
// what a push build is for.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
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

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // One key, or a throwaway one.
            //
            // Until 2026-09-27 this was always `debug`, and the workflow kept
            // no keystore — so each CI runner found no ~/.android/debug.keystore,
            // the Android Gradle Plugin generated one with a fresh key pair,
            // and threw it away. Every build was signed differently, which
            // meant a new APK could not install over an old one (Android
            // refuses a package whose signature changed) and an uninstall
            // took `user.db` with it: the diary, the goals, the anonymous
            // account. It also made Android App Links impossible, because
            // `assetlinks.json` names one SHA-256 and there was never one to
            // name.
            //
            // The fallback stays for forks and fresh clones: they compile and
            // catch a Gradle or manifest break, they simply will not install
            // over a properly signed build.
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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
    // Google Play's Install Referrer, read once on first launch for an
    // invite's code (08-sangat IV6). MainActivity calls it directly rather
    // than through a plugin.
    implementation("com.android.installreferrer:installreferrer:2.2")
}

flutter {
    source = "../.."
}
