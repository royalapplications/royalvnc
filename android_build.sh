#!/usr/bin/env bash

set -e

SWIFT_ANDROID_SDK_BASE="${HOME}/.swiftpm/swift-sdks/swift-6.1-RELEASE-android-24-0.1.artifactbundle/swift-6.1-release-android-24-sdk/android-27c-sysroot/usr/lib"
SWIFT_ANDROID_SDK_ARM64="${SWIFT_ANDROID_SDK_BASE}/aarch64-linux-android"
SWIFT_ANDROID_SDK_X86_64="${SWIFT_ANDROID_SDK_BASE}/x86_64-linux-android"

KOTLIN_TARGET_JNI_BASE="Bindings/kotlin/RoyalVNCAndroidTest/app/src/main/jniLibs"
KOTLIN_TARGET_JNI_ARM64="${KOTLIN_TARGET_JNI_BASE}/arm64-v8a"
KOTLIN_TARGET_JNI_X86_64="${KOTLIN_TARGET_JNI_BASE}/x86_64"

declare -a SWIFT_SDK_LIBS=(
	"libandroid-spawn.so"
	"libBlocksRuntime.so"
	"libc++_shared.so"
	"libdispatch.so"
	"libFoundationEssentials.so"
	"libswift_Builtin_float.so"
	"libswift_Concurrency.so"
	"libswift_math.so"
	"libswift_RegexParser.so"
	"libswift_StringProcessing.so"
	"libswiftAndroid.so"
	"libswiftCore.so"
	"libswiftDispatch.so"
	"libswiftRegexBuilder.so"
	"libswiftSynchronization.so"
	"libz.so"
)

echo "Building RoyalVNC for Android"
skip android build --configuration release

echo "Cleaning Kotlin JNI ARM64 libraries"
pushd "${KOTLIN_TARGET_JNI_ARM64}"
rm -f *.so
popd

echo "Cleaning Kotlin JNI x86_64 libraries"
pushd "${KOTLIN_TARGET_JNI_X86_64}"
rm -f *.so
popd

echo "Copying RoyalVNC ARM64 library"
cp -f \
	.build/aarch64-unknown-linux-android24/release/libRoyalVNCKit.so \
	"${KOTLIN_TARGET_JNI_ARM64}/"

echo "Copying RoyalVNC x86_64 library"
cp -f \
	.build/x86_64-unknown-linux-android24/release/libRoyalVNCKit.so \
	"${KOTLIN_TARGET_JNI_X86_64}/"

echo "Copying Swift ARM64 libraries"
for swift_sdk_lib in "${SWIFT_SDK_LIBS[@]}"
do
   cp -f \
		"${SWIFT_ANDROID_SDK_ARM64}/${swift_sdk_lib}" \
		"${KOTLIN_TARGET_JNI_ARM64}/"
done

echo "Copying Swift x86_64 libraries"
for swift_sdk_lib in "${SWIFT_SDK_LIBS[@]}"
do
   cp -f \
		"${SWIFT_ANDROID_SDK_X86_64}/${swift_sdk_lib}" \
		"${KOTLIN_TARGET_JNI_X86_64}/"
done

echo "All Done - Open Bindings/kotlin/RoyalVNCAndroidTest in Android Studio now"