import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val appVersionCode = 1
val appVersionName = "0.1.0"

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(::load)
    }
}

fun signingValue(envKey: String, localPropertyKey: String): String? {
    val envValue = System.getenv(envKey)?.trim()
    if (!envValue.isNullOrEmpty()) {
        return envValue
    }

    val localValue = localProperties.getProperty(localPropertyKey)?.trim()
    return localValue?.takeIf { it.isNotEmpty() }
}

val debugKeystoreFile = rootProject.file("debug.keystore")
val debugStorePassword = signingValue(
    envKey = "CURATOR_DEBUG_STORE_PASSWORD",
    localPropertyKey = "curator.debug.storePassword",
) ?: "android"
val debugKeyAlias = signingValue(
    envKey = "CURATOR_DEBUG_KEY_ALIAS",
    localPropertyKey = "curator.debug.keyAlias",
) ?: "androiddebugkey"
val debugKeyPassword = signingValue(
    envKey = "CURATOR_DEBUG_KEY_PASSWORD",
    localPropertyKey = "curator.debug.keyPassword",
) ?: "android"

val releaseStoreFilePath = signingValue(
    envKey = "CURATOR_RELEASE_STORE_FILE",
    localPropertyKey = "curator.release.storeFile",
)
val releaseStorePassword = signingValue(
    envKey = "CURATOR_RELEASE_STORE_PASSWORD",
    localPropertyKey = "curator.release.storePassword",
)
val releaseKeyAlias = signingValue(
    envKey = "CURATOR_RELEASE_KEY_ALIAS",
    localPropertyKey = "curator.release.keyAlias",
)
val releaseKeyPassword = signingValue(
    envKey = "CURATOR_RELEASE_KEY_PASSWORD",
    localPropertyKey = "curator.release.keyPassword",
)

val releaseSigningConfigured = listOf(
    releaseStoreFilePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "com.curator.curator_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        getByName("debug") {
            storeFile = debugKeystoreFile
            storePassword = debugStorePassword
            keyAlias = debugKeyAlias
            keyPassword = debugKeyPassword
        }
        create("release") {
            if (releaseSigningConfigured) {
                storeFile = rootProject.file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.curator.curator_mobile"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

val liteRtLmVersion = "0.10.2"

dependencies {
    implementation("com.google.ai.edge.litertlm:litertlm-android:$liteRtLmVersion")
}

gradle.taskGraph.whenReady {
    val releaseBuildRequested = allTasks.any { task ->
        val taskName = task.name.lowercase()
        taskName.contains("release") &&
            (
                taskName.contains("assemble") ||
                    taskName.contains("bundle") ||
                    taskName.contains("package") ||
                    taskName.contains("sign")
                )
    }

    if (releaseBuildRequested && !releaseSigningConfigured) {
        throw GradleException(
            "Release signing is not configured. Set CURATOR_RELEASE_STORE_FILE, " +
                "CURATOR_RELEASE_STORE_PASSWORD, CURATOR_RELEASE_KEY_ALIAS, and " +
                "CURATOR_RELEASE_KEY_PASSWORD, or add curator.release.* entries to " +
                "mobile/android/local.properties.",
        )
    }
}

flutter {
    source = "../.."
}
