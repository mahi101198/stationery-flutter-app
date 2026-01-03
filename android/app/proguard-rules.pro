# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Razorpay specific rules
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**
-keep @proguard.annotation.Keep class *
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keepclassmembers @proguard.annotation.KeepClassMembers class * {
    *;
}

# Network and HTTP
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# General Android
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers @kotlinx.serialization.Serializable class * {
    *** Companion;
}

# Google Play Core and Google Pay
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# UPI Payment related
-keep class net.one97.paytm.** { *; }
-keep class com.phonepe.** { *; }
-dontwarn net.one97.paytm.**
-dontwarn com.phonepe.**

# Aggressive size reduction rules
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove unused code
-dontwarn **
-ignorewarnings

# Remove debug information
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Remove unused resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Aggressive shrinking
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}

-keep public class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}

-keepnames @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembernames class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

-keepnames class * implements android.os.Parcelable {
    public static final ** CREATOR;
}