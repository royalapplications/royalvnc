#Requires -PSEdition Core -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

. $PSScriptRoot\utils.ps1

$nmake = (Get-Command nmake.exe -ErrorAction Stop)
$swift = (Get-Command swift.exe -ErrorAction Stop)

$nmake,$swift | Format-Table -AutoSize -HideTableHeaders -Property Source 

exec { swift --version }

$BIN_DIR = Join-Path $ROOT_PATH "bin" -Resolve

function download_and_extract([string]$repo, [string]$version, [string]$file) {
    [string]$filename = "${file}-${version}.zip"
    if (-not (file_exists "${BIN_DIR}\${filename}")) {
        exec { curl.exe -sSL -o "${BIN_DIR}\${filename}" "https://github.com/libtom/${repo}/releases/download/v${version}/${filename}" }
    }

    Expand-Archive "${BIN_DIR}\${filename}" "${BIN_DIR}"
    return "${BIN_DIR}\${repo}-${version}"
}

$mathDir  = download_and_extract 'libtommath'  '1.3.0'  'ltm'
$cryptDir = download_and_extract 'libtomcrypt' '1.18.2' 'crypt'

function nmake_build([string]$dir, [string[]]$nmakeArgs) {
    Write-Host "Building ${dir}" -ForegroundColor Cyan

    Push-Location $dir
    try {
        exec { nmake.exe /nologo -f "makefile.msvc" $nmakeArgs }
    } finally {
        Pop-Location
    }
}

# Needed because the endian detection macros does not work on arm64 in a released version.
# This was fixed but no new release was made -- avoid warnings on x64 by not overrinding there.
# ref. https://github.com/libtom/libtomcrypt/commit/c4d22b904604f2f49c717ffc9bf86678658117b0#diff-2db5eece44c5b2ec42c2e2a08d847e6b0e3723d7d11bf7d5bda16f20fe795ff9R83
[string]$endian_flags = ''
if ($HOST_MSVC_ARCH -eq "arm64") { 
    $endian_flags = '/DENDIAN_LITTLE /DENDIAN_64BITWORD /DLTC_FAST'
}

nmake_build $mathDir  @()
nmake_build $cryptDir @(
    "CFLAGS=/DUSE_LTM /DLTM_DESC ${endian_flags} /I${mathDir}"
    "EXTRALIBS=${mathDir}\tommath.lib"
)

function make_bundle([string]$targetDir, [string]$headers, [string]$libs) {
    Write-Host "Bunding to ${targetDir}" -ForegroundColor Cyan

    remove_dir  "${targetDir}\include"
    create_dir  "${targetDir}\include"
    remove_file "${targetDir}\*.lib"

    Copy-Item "${headers}" "${targetDir}\include" -Force
    Copy-Item "${libs}"    "${targetDir}"         -Force
}

make_bundle "${ROOT_PATH}\Sources\libtommath-win"  "${mathDir}\*.h"              "${mathDir}\*.lib"
make_bundle "${ROOT_PATH}\Sources\libtomcrypt-win" "${cryptDir}\src\headers\*.h" "${cryptDir}\*.lib"
