import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


        android {
            namespace = "com.bobde6.btcroundup"
            compileSdk = 36
            ndkVersion = "27.0.12077973"

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            kotlin {
                compilerOptions {
                    jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                }
            }

            defaultConfig {
                applicationId = "com.bobde6.btcroundup"
                minSdk = flutter.minSdkVersion
                //noinspection OldTargetApi
                targetSdk = 35
                versionCode = 1
                versionName = "1.0.0"
                multiDexEnabled = true
            }

            signingConfigs {
                create("release") {
                    val keyProperties = Properties()
                    val keyPropertiesFile = rootProject.file("key.properties")

                    if (keyPropertiesFile.exists()) {
                        keyPropertiesFile.inputStream().use { stream ->
                            keyProperties.load(stream)
                        }
                    }

                    storeFile = file(keyProperties.getProperty("storeFile", "btcroundup.keystore"))
                    storePassword = keyProperties.getProperty("storePassword", "")
                    keyAlias = keyProperties.getProperty("keyAlias", "btcroundup")
                    keyPassword = keyProperties.getProperty("keyPassword", "")
                }
            }

            buildTypes {
                release {
                    isMinifyEnabled = true
                    isShrinkResources = true
                    proguardFiles(
                        getDefaultProguardFile("proguard-android-optimize.txt"),
                        "proguard-rules.pro"
                    )
                    signingConfig = signingConfigs.getByName("release")
                }
                debug {
                    signingConfig = signingConfigs.getByName("debug")
                }
            }
        }

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("androidx.multidex:multidex:2.0.1")
}
