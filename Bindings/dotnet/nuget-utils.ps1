#Requires -PSEdition Core -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandArgumentPassing = 'Standard'
$PSNativeCommandUseErrorActionPreference = $true
$PSStyle.OutputRendering = 'ANSI'

$NUGET_VERSION = $env:NUGET_VERSION
if (-not $NUGET_VERSION) {
    throw "NUGET_VERSION was not passed in -- aborting"
}

$REPO_ROOT = Join-Path $PSScriptRoot '../..' -Resolve

$HOST_OS = if ($IsLinux) { 'linux' }
    elseif ($IsMacOS)    { 'macOS' }
    elseif ($IsWindows)  { 'windows' }
    else { throw 'Unknown OS -- aborting' }

$HOST_ARCH = 'x64'
$HOST_ARCH_SWIFT = 'x86_64'
if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ieq 'ARM64') {
    $HOST_ARCH = 'arm64'
    $HOST_ARCH_SWIFT = if ($IsMacOS) { 'arm64' } else { 'aarch64' }
}

$NUGET_GIT_COMMIT = $env:NUGET_GIT_COMMIT
if (-not $NUGET_GIT_COMMIT) {
    [string]$NUGET_GIT_COMMIT = (& git rev-parse HEAD)
    Write-Host "Auto-detected NUGET_GIT_COMMIT: ${NUGET_GIT_COMMIT}"
}

$NUGET_RID = $env:NUGET_RID
if (-not $NUGET_RID) {
    $NUGET_RID = switch ($HOST_OS) {
        "macOS" { "osx" }
        "windows" { "win-${HOST_ARCH}" }
        default { "${HOST_OS}-${HOST_ARCH}" }
    }
    Write-Host "Auto-detected NUGET_RID: ${NUGET_RID}"
}

$NATIVE_LIB = switch ($HOST_OS) {
    'linux' { 'libRoyalVNCKit.so' }
    'macOS' { 'libRoyalVNCKit.dylib' }
    'windows'  { 'RoyalVNCKit.dll' }
}

Write-Host "OS: ${HOST_OS}; NuGet RID: ${NUGET_RID}; arch: ${HOST_ARCH} (.NET), ${HOST_ARCH_SWIFT} (LLVM/Swift); native lib: ${NATIVE_LIB}"

function exec([scriptblock]$command) {
    $nl_indent = [Environment]::NewLine + '    '
    $exec_clean_rx = [regex]::new('`\s*$\s+', [System.Text.RegularExpressions.RegexOptions]'Multiline,CultureInvariant,NonBacktracking,ExplicitCapture')

    $clean_command = $exec_clean_rx.Replace($command.ToString().Trim(), $nl_indent)
    $clean_command = ("@`"`n$clean_command`n`"@" | Invoke-Expression)

    Write-Host $clean_command -ForegroundColor cyan
    Invoke-Command -ScriptBlock $command

    if ($lastexitcode -ne 0) { throw $lastexitcode }
}
