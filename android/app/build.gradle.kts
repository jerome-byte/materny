plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.materny"
    
    // On utilise bien le SDK 36 détecté par flutter doctor
    compileSdk = 36
    buildToolsVersion = "36.0.0" // AJOUTEZ CETTE LIGNE
    
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.materny"
        minSdk = flutter.minSdkVersion
        
        // PASSEZ À 35 OU 36 POUR ÉVITER LES CONFLITS DE RESSOURCES
        targetSdk = 35 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}