# Flutter Specific ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Prevent R8 from removing classes that might be needed at runtime
-dontwarn io.flutter.embedding.**
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Optimization settings
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
-optimizationpasses 5

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the BuildConfig class
-keep class com.example.** { *; }

# Keep Serializable classes and their members
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Preserve all annotations
-keepattributes *Annotation*