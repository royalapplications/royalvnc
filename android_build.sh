#!/usr/bin/env bash

set -e

ANDROID_API_LEVEL="29"

SWIFT_ANDROID_ROOT="${HOME}/Library/org.swift.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle/swift-android"

SWIFT_ANDROID_NDK_BASE="${SWIFT_ANDROID_ROOT}/ndk-sysroot/usr/lib"
SWIFT_ANDROID_NDK_ARM64="${SWIFT_ANDROID_NDK_BASE}/aarch64-linux-android"

SWIFT_ANDROID_SDK_BASE="${SWIFT_ANDROID_ROOT}/swift-resources/usr/lib"
SWIFT_ANDROID_SDK_ARM64="${SWIFT_ANDROID_SDK_BASE}/swift-aarch64/android"

KOTLIN_PROJECT_DIR="Bindings/kotlin/RoyalVNCAndroidTest"

declare -a ROYALVNC_LIBS=(
	"${SWIFT_ANDROID_NDK_ARM64}/${ANDROID_API_LEVEL}/libz.so"
)

declare -a SWIFT_RUNTIME_LIBS=(
	# NDK C++
	"${SWIFT_ANDROID_NDK_ARM64}/libc++_shared.so"

	# Swift SDK for Android
	"${SWIFT_ANDROID_SDK_ARM64}/libBlocksRuntime.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libdispatch.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libFoundationEssentials.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswift_Builtin_float.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswift_Concurrency.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswift_math.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswift_RegexParser.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswift_StringProcessing.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswiftAndroid.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswiftCore.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswiftDispatch.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswiftRegexBuilder.so"
	"${SWIFT_ANDROID_SDK_ARM64}/libswiftSynchronization.so"
)

echo "Building RoyalVNC for Android"
skip android build \
	--configuration release \
	--no-bridge \
	--android-api-level ${ANDROID_API_LEVEL} \
	--arch aarch64

# royalvnc module
ROYALVNC_JNILIBS_DIR="${KOTLIN_PROJECT_DIR}/royalvnc/src/main/jniLibs/arm64-v8a"

echo "Cleaning royalvnc JNI libraries"
pushd "${ROYALVNC_JNILIBS_DIR}"
rm -f *.so
popd

echo "Copying RoyalVNC library"
cp -f \
	.build/aarch64-unknown-linux-android${ANDROID_API_LEVEL}/release/libRoyalVNCKit.so \
	"${ROYALVNC_JNILIBS_DIR}/"

echo "Copying RoyalVNC dependency libraries"
for royalvnc_lib in "${ROYALVNC_LIBS[@]}"
do
   cp -f \
		"${royalvnc_lib}" \
		"${ROYALVNC_JNILIBS_DIR}/"
done

echo "Building royalvnc.aar Maven bundle"
pushd "${KOTLIN_PROJECT_DIR}"
./gradlew :royalvnc:publishMavenBundle
popd

ROYALVNC_BUNDLE_FILE="${KOTLIN_PROJECT_DIR}/royalvnc/build/distributions/royalvnc.zip"
if [[ -f "${ROYALVNC_BUNDLE_FILE}" ]]; then
	echo "Found ${ROYALVNC_BUNDLE_FILE}"
else
	echo "Error: cannot find ${ROYALVNC_BUNDLE_FILE}"
	exit 1
fi

# swiftRuntime module
SWIFTRUNTIME_JNILIBS_DIR="${KOTLIN_PROJECT_DIR}/swiftRuntime/src/main/jniLibs/arm64-v8a"

echo "Cleaning swiftRuntime JNI libraries"
pushd "${SWIFTRUNTIME_JNILIBS_DIR}"
rm -f *.so
popd

echo "Copying Swift runtime libraries"
for swiftRuntime_lib in "${SWIFT_RUNTIME_LIBS[@]}"
do
   cp -f \
		"${swiftRuntime_lib}" \
		"${SWIFTRUNTIME_JNILIBS_DIR}/"
done

echo "Building swiftRuntime.aar Maven bundle"
pushd "${KOTLIN_PROJECT_DIR}"
./gradlew :swiftRuntime:publishMavenBundle
popd

SWIFTRUNTIME_BUNDLE_FILE="${KOTLIN_PROJECT_DIR}/swiftRuntime/build/distributions/swiftRuntime_android.zip"
if [[ -f "${SWIFTRUNTIME_BUNDLE_FILE}" ]]; then
	echo "Found ${SWIFTRUNTIME_BUNDLE_FILE}"
else
	echo "Error: cannot find ${SWIFTRUNTIME_BUNDLE_FILE}"
	exit 1
fi

echo "All Done - Open Bindings/kotlin/RoyalVNCAndroidTest in Android Studio now"