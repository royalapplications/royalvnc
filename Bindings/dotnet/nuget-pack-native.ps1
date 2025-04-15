#Requires -PSEdition Core -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandArgumentPassing = 'Standard'
$PSNativeCommandUseErrorActionPreference = $true
$PSStyle.OutputRendering = 'ANSI'

. $PSScriptRoot/nuget-utils.ps1

$CONFIGURATION = 'Release'

$DEMO_DIR = Join-Path $REPO_ROOT 'Bindings/dotnet/RoyalApps.RoyalVNCKit.Demo' -Resolve
exec { dotnet build --configuration $CONFIGURATION $DEMO_DIR }

$NATIVE_DIR = Join-Path $REPO_ROOT 'Bindings/dotnet/RoyalApps.RoyalVNCKit.native' -Resolve
$NUSPEC_FILE = Join-Path $NATIVE_DIR 'native.nuspec' -Resolve

if ($HOST_OS -eq 'windows') {
    $NUSPEC_FILE = Join-Path $NATIVE_DIR 'windows.nuspec' -Resolve

    $SWIFT_CRT_PATH = (Get-Command swiftCRT.dll -ErrorAction Stop).Source
    $SWIFT_RT_DIR = Split-Path $SWIFT_CRT_PATH -Parent
    Write-Host "Auto-detected Swift runtime dir: ${SWIFT_RT_DIR}"

    $NUGET_SWIFT_RT_VERSION = $env:NUGET_SWIFT_RT_VERSION
    if (-not $NUGET_SWIFT_RT_VERSION) {
        [string]$version = (& swift --version)
        if ($version -imatch 'Swift version (\d+\.\d+(\.\d+)?)') {
            $NUGET_SWIFT_RT_VERSION = $Matches.1
            Write-Host "Auto-detected NUGET_SWIFT_RT_VERSION: ${NUGET_SWIFT_RT_VERSION}"
        }
        else {
            throw "NUGET_SWIFT_RT_VERSION not set and auto-detection failed for: `n${version}"
        }
    }

    Write-Host "Creating RoyalApps.native.SwiftRuntime.${NUGET_RID}  NuGet package"

    exec {
        dotnet pack "${NATIVE_DIR}/native.pkgproj" `
        "-p:NuspecFile=${NATIVE_DIR}/windows.SwiftRuntime.nuspec" `
        "-p:NuspecBasePath=${NATIVE_DIR}" `
        "-p:NuspecProperties=`"NUGET_GIT_COMMIT=${NUGET_GIT_COMMIT};NUGET_RID=${NUGET_RID};SWIFT_RT_DIR=${SWIFT_RT_DIR};NUGET_SWIFT_RT_VERSION=${NUGET_SWIFT_RT_VERSION}`""
    }
} else {
    $NUGET_SWIFT_RT_VERSION = ''
}

Write-Host "Creating RoyalApps.RoyalVNCKit.native.${NUGET_RID}  NuGet package"

$NUGET_LIB = Join-Path $DEMO_DIR "bin/${CONFIGURATION}/${NATIVE_LIB}" -Resolve

exec {
    dotnet pack "${NATIVE_DIR}/native.pkgproj" `
    "-p:NuspecFile=${NUSPEC_FILE}" `
    "-p:NuspecBasePath=${NATIVE_DIR}" `
    "-p:NuspecProperties=`"NUGET_VERSION=${NUGET_VERSION};NUGET_GIT_COMMIT=${NUGET_GIT_COMMIT};NUGET_RID=${NUGET_RID};NUGET_SWIFT_RT_VERSION=${NUGET_SWIFT_RT_VERSION};NUGET_LIB_NAME=${NATIVE_LIB};NUGET_LIB=${NUGET_LIB}`""
}
