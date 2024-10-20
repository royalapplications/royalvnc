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
    [string]$filename = "${file}-${version}.tar.xz"
    if (-not (file_exists "${BIN_DIR}\${filename}")) {
        exec { curl.exe -L -o "${BIN_DIR}\${filename}" "https://github.com/libtom/${repo}/releases/download/v${version}/${filename}" }
    }

    [string]$directory = "${BIN_DIR}\${repo}-${version}"
    if (-not (dir_exists $directory)) {
        exec { tar.exe -xzf "${BIN_DIR}\${filename}" -C "${BIN_DIR}" }
    }

    return $directory
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

nmake_build $mathDir  @()
nmake_build $cryptDir @(
    "CFLAGS=/DUSE_LTM /DLTM_DESC /DENDIAN_LITTLE /DENDIAN_64BITWORD /DLTC_FAST /I${mathDir}"
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
