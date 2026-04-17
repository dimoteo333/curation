# Keep MediaPipe and LiteRT runtime classes that may be referenced from native code.
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
