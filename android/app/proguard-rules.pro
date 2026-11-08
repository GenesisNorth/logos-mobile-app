# ProGuard and R8 rules for LOGOS IN ME

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Audio Players & ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# Record Plugin
-keep class com.llfbandit.record.** { *; }

# Speech to Text (on-device recitation recognition)
-keep class com.csdcorp.speech_to_text.** { *; }

# Gson (used by flutter_local_notifications for scheduled notifications)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.errorprone.annotations.**

# Supabase & JSON serialization
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers enum * { *; }

# Flutter engine references Play Core deferred components (unused by this app)
-dontwarn com.google.android.play.core.**
