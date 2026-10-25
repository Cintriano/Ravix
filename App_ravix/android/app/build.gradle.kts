import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de release fora do repositório (~/.android/ravix-release.jks), com a
// senha em android/key.properties (ignorado pelo Git). Sem o arquivo, como no
// CI, o release é assinado com a chave de debug.
val propriedadesDaChave =
    Properties().apply {
        val arquivo = rootProject.file("key.properties")
        if (arquivo.exists()) arquivo.inputStream().use { load(it) }
    }
val temChaveDeRelease = propriedadesDaChave.getProperty("storeFile") != null

android {
    namespace = "com.cintriano.ravix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Nome do app por tipo de build (resValue app_name).
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cintriano.ravix"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Ravix")
    }

    signingConfigs {
        if (temChaveDeRelease) {
            create("release") {
                storeFile = file(propriedadesDaChave.getProperty("storeFile"))
                storePassword = propriedadesDaChave.getProperty("storePassword")
                keyAlias = propriedadesDaChave.getProperty("keyAlias")
                keyPassword = propriedadesDaChave.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // Debug e profile convivem com o app de uso no mesmo aparelho, cada
        // um com os próprios dados.
        getByName("debug") {
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "Ravix (debug)")
        }
        getByName("profile") {
            applicationIdSuffix = ".profile"
            resValue("string", "app_name", "Ravix (profile)")
        }
        release {
            signingConfig =
                signingConfigs.getByName(if (temChaveDeRelease) "release" else "debug")
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
