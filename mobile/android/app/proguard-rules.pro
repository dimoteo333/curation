# Keep LiteRT-LM and LiteRT runtime classes that may be referenced from native code.
-keep class com.google.ai.edge.litertlm.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class * {
    native <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn com.google.protobuf.**
-dontwarn org.tensorflow.lite.**

# Keep SQLite access paths used by Android framework and sqflite.
-keep class android.database.sqlite.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Keep Flutter embedding and generated plugin registrant classes used at startup.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn io.flutter.**
