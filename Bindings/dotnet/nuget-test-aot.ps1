#!/usr/bin/env pwsh
#Requires -PSEdition Core -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandArgumentPassing = 'Standard'
$PSNativeCommandUseErrorActionPreference = $true
$PSStyle.OutputRendering = 'ANSI'

. $PSScriptRoot/nuget-utils.ps1

$TEST_AOT_DIR = Join-Path $REPO_ROOT 'Bindings/dotnet/TestAOT' -Resolve

$TEST_RID = $NUGET_RID
if ($HOST_OS -eq "macOS") {
    $TEST_RID = "${TEST_RID}-${HOST_ARCH}"
}

Write-Host "Building .NET bindings AOT/package test for ${TEST_RID}"
exec {
    dotnet publish --runtime "${TEST_RID}" $TEST_AOT_DIR `
    "-p:RoyalVNCKit_NativeRID=${NUGET_RID}" `
    "-p:RoyalVNCKit_NupkgVersion=${NUGET_VERSION}"
}

$TEST_AOT_PROGRAM = "${TEST_AOT_DIR}/bin/Release/${TEST_RID}/publish/TestAOT"
if ($HOST_OS -eq 'windows') {
    $TEST_AOT_PROGRAM += '.exe'
}
$TEST_AOT_PROGRAM = Resolve-Path $TEST_AOT_PROGRAM

Write-Host "Testing .NET bindings with AOT for ${TEST_RID}"
exec { & $TEST_AOT_PROGRAM --version }
