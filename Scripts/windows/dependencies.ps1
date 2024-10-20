#Requires -PSEdition Core -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

. $PSScriptRoot\utils.ps1

$cmake = (Get-Command nmake.exe -ErrorAction Stop)
$swift = (Get-Command swift.exe -ErrorAction Stop)

$cmake,$swift | Format-Table -AutoSize -HideTableHeaders -Property Source 

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

function build([string]$dir, [string[]]$nmakeArgs) {
    Write-Host "Building ${dir}" -ForegroundColor Cyan

    Push-Location $dir
    try {
        exec { nmake.exe /nologo -f "makefile.msvc" $nmakeArgs }
    } finally {
        Pop-Location
    }
}

build $mathDir  @()
build $cryptDir @(
    "CFLAGS=/DUSE_LTM /DLTM_DESC /DENDIAN_LITTLE /DENDIAN_64BITWORD /DLTC_FAST /I${mathDir}"
    "EXTRALIBS=${mathDir}\tommath.lib"
)

function make_bundle([string]$targetDir, [string]$headersDir, [string]$libDir) {
    Write-Host "Bunding to ${targetDir}" -ForegroundColor Cyan

    Push-Location "${ROOT_PATH}\Sources"
    try {
        remove_dir  "${targetDir}\include"
        create_dir  "${targetDir}\include"
        remove_file "${targetDir}\*.lib"

        Copy-Item "${headersDir}\*.h" "${targetDir}\include" -Force
        Copy-Item "${libDir}\*.lib"   "${targetDir}"         -Force
    } finally {
        Pop-Location
    }
}

make_bundle "${ROOT_PATH}\Sources\libtommath-win"  "${mathDir}"              "${mathDir}"
make_bundle "${ROOT_PATH}\Sources\libtomcrypt-win" "${cryptDir}\src\headers" "${cryptDir}"
