#Requires -PSEdition Core -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

. $PSScriptRoot\utils.ps1

$cmake = (Get-Command cmake.exe -ErrorAction Stop)
$ninja = (Get-Command ninja.exe -ErrorAction Stop)
$swift = (Get-Command swift.exe -ErrorAction Stop)

$cmake,$ninja,$swift | Format-Table -AutoSize -HideTableHeaders -Property Source 

exec { cmake --version }
exec { ninja --version }
exec { swift --version }

$BIN_DIR = Join-Path $ROOT_PATH 'bin' -Resolve

function download_and_extract([string]$releaseFile, [string]$localName) {
    [string]$filename = "${BIN_DIR}\${localName}.zip"
    if (-not (file_exists $filename)) {
        exec { curl.exe -sSL -o $filename "https://github.com/${releaseFile}" }
    }
    [string]$dirname = "${BIN_DIR}\${localName}"
    if (-not (dir_exists $dirname)) {
        Expand-Archive $filename $BIN_DIR
    }
    return $dirname
}

$zlibDir = download_and_extract 'zlib-ng/zlib-ng/archive/refs/tags/2.2.2.zip' 'zlib-ng-2.2.2'

[string]$BUNDLE_DIR = "${BIN_DIR}\deps-windows"
clean_dir $BUNDLE_DIR

function cmake_build_install([string]$dir, [string[]]$cmakeArgs) {
    Write-Host "Building ${dir} with cmake" -ForegroundColor Cyan
    
    [string]$buildDir = "${dir}-build"
    clean_dir $buildDir
    Push-Location $buildDir
    try {
        exec { cmake -GNinja -S $dir $cmakeArgs }
        exec { cmake --build $buildDir --target install }
    } finally {
        Pop-Location
    }
}

cmake_build_install $zlibDir @(
    '-DZLIB_COMPAT=ON'
    '-DZLIB_ENABLE_TESTS=OFF'
    '-DWITH_GTEST=OFF'
    '-DCMAKE_BUILD_TYPE=Release'
    "-DCMAKE_INSTALL_PREFIX=${BUNDLE_DIR}"
)
