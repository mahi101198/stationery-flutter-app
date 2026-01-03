import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.devay.rps_stationery"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        getByName("debug") {
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeFile = file("debug.keystore")
            storePassword = "android"
        }
        // Release signing configuration - uses key.properties file for security
        val keystorePropertiesFile = file("key.properties")
        val releaseKeyAlias: String?
        val releaseKeyPassword: String?
        val releaseStoreFile: String?
        val releaseStorePassword: String?
        
        if (keystorePropertiesFile.exists()) {
            val keystoreProperties = Properties()
            FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
            releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
            releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
            releaseStoreFile = keystoreProperties.getProperty("storeFile")
            releaseStorePassword = keystoreProperties.getProperty("storePassword")
        } else {
            // Fallback: Use environment variables if key.properties doesn't exist
            // This allows CI/CD pipelines to use environment variables
            releaseKeyAlias = System.getenv("RELEASE_KEY_ALIAS") ?: "release-key"
            releaseKeyPassword = System.getenv("RELEASE_KEY_PASSWORD")
            releaseStoreFile = System.getenv("RELEASE_STORE_FILE") ?: "release-key.keystore"
            releaseStorePassword = System.getenv("RELEASE_STORE_PASSWORD")
        }
        
        if (!releaseKeyPassword.isNullOrEmpty() && !releaseStorePassword.isNullOrEmpty() && releaseKeyAlias != null && releaseStoreFile != null) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword!!
                storeFile = file(releaseStoreFile)
                storePassword = releaseStorePassword!!
            }
        } else {
            // If neither key.properties nor env vars are set, throw error
            throw GradleException(
                "Release signing not configured. Please create android/app/key.properties " +
                "or set RELEASE_KEY_PASSWORD and RELEASE_STORE_PASSWORD environment variables."
            )
        }
    }

    defaultConfig {
        applicationId = "com.devay.rps_stationery"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Size optimizations
        vectorDrawables.useSupportLibrary = true
        // Only enable multiDex if needed (check if app exceeds 65K method limit)
        // multiDexEnabled = true
    }

    buildTypes {
        release {
            // Production signing configuration
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Production build optimizations
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
            isPseudoLocalesEnabled = false
            isZipAlignEnabled = true
            
            // Aggressive size optimizations
            isCrunchPngs = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Google Play Services
    implementation("com.google.android.gms:play-services-base:18.5.0")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("com.google.android.gms:play-services-maps:19.0.0")
}
