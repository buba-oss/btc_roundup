# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Core (missing classes)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep your app classes
-keep class com.bobde6.btcroundup.** { *; }

# Flutter engine & plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Prevent R8 from stripping Flutter registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# AndroidX Biometric
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# AndroidX Fragment (required by FlutterFragmentActivity)
-keep class androidx.fragment.app.** { *; }
-dontwarn androidx.fragment.app.**

# Keep Kotlin metadata for reflection
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Flutter platform channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler *;
}

# Keep generated localization classes
-keep class **.AppLocalizations { *; }
-keep class **.AppLocalizations_* { *; }