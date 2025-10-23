#!/usr/bin/env bash

set -e

ANDROID_API_LEVEL="29"

SWIFT_ANDROID_ROOT="${HOME}/Library/org.swift.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle/swift-android"

SWIFT_ANDROID_NDK_BASE="${SWIFT_ANDROID_ROOT}/ndk-sysroot/usr/lib"
SWIFT_ANDROID_NDK_ARM64="${SWIFT_ANDROID_NDK_BASE}/aarch64-linux-android"
SWIFT_ANDROID_NDK_X86_64="${SWIFT_ANDROID_NDK_BASE}/x86_64-linux-android"

SWIFT_ANDROID_SDK_BASE="${SWIFT_ANDROID_ROOT}/swift-resources/usr/lib"
SWIFT_ANDROID_SDK_ARM64="${SWIFT_ANDROID_SDK_BASE}/swift-aarch64/android"
SWIFT_ANDROID_SDK_X86_64="${SWIFT_ANDROID_SDK_BASE}/swift-x86_64/android"

KOTLIN_TARGET_JNI_BASE="Bindings/kotlin/RoyalVNCAndroidTest/app/src/main/jniLibs"
KOTLIN_TARGET_JNI_ARM64="${KOTLIN_TARGET_JNI_BASE}/arm64-v8a"
KOTLIN_TARGET_JNI_X86_64="${KOTLIN_TARGET_JNI_BASE}/x86_64"

declare -a SWIFT_NDK_LIBS=(
	"${ANDROID_API_LEVEL}/libz.so"
	"libc++_shared.so"
)

declare -a SWIFT_SDK_LIBS=(
	"libBlocksRuntime.so"
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
)

echo "Building RoyalVNC for Android"
skip android build \
	--configuration release \
	--no-bridge \
	--android-api-level ${ANDROID_API_LEVEL} \
	--arch aarch64 \
	--arch x86_64

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
	.build/aarch64-unknown-linux-android${ANDROID_API_LEVEL}/release/libRoyalVNCKit.so \
	"${KOTLIN_TARGET_JNI_ARM64}/"

echo "Copying RoyalVNC x86_64 library"
cp -f \
	.build/x86_64-unknown-linux-android${ANDROID_API_LEVEL}/release/libRoyalVNCKit.so \
	"${KOTLIN_TARGET_JNI_X86_64}/"

# Swift Libs
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

# NDK Libs
echo "Copying NDK ARM64 libraries"
for swift_ndk_lib in "${SWIFT_NDK_LIBS[@]}"
do
   cp -f \
		"${SWIFT_ANDROID_NDK_ARM64}/${swift_ndk_lib}" \
		"${KOTLIN_TARGET_JNI_ARM64}/"
done

echo "Copying NDK x86_64 libraries"
for swift_ndk_lib in "${SWIFT_NDK_LIBS[@]}"
do
   cp -f \
		"${SWIFT_ANDROID_NDK_X86_64}/${swift_ndk_lib}" \
		"${KOTLIN_TARGET_JNI_X86_64}/"
done

echo "All Done - Open Bindings/kotlin/RoyalVNCAndroidTest in Android Studio now"