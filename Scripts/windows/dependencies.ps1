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

function download_and_extract([string]$releaseFile, [string]$localName) {
    [string]$filename = "${localName}.zip"
    if (-not (file_exists "${BIN_DIR}\${filename}")) {
        exec { curl.exe -sSL -o "${BIN_DIR}\${filename}" "https://github.com/${releaseFile}" }
    }
    if (-not (dir_exists "${BIN_DIR}\${localName}")) {
        remove_dir "${BIN_DIR}\_tmp"
        create_dir "${BIN_DIR}\_tmp"
        Expand-Archive "${BIN_DIR}\${filename}" "${BIN_DIR}\_tmp"

        if (dir_exists "${BIN_DIR}\_tmp\${localName}") {
            Move-Item "${BIN_DIR}\_tmp\${localName}" "${BIN_DIR}\${localName}"
        } else {
            Move-Item "${BIN_DIR}\_tmp" "${BIN_DIR}\${localName}"
        }
    }
    return Join-Path $BIN_DIR $localName -Resolve
}

$mathDir  = download_and_extract 'libtom/libtommath/releases/download/v1.3.0/ltm-1.3.0.zip'      'libtommath-1.3.0'
$cryptDir = download_and_extract 'libtom/libtomcrypt/releases/download/v1.18.2/crypt-1.18.2.zip' 'libtomcrypt-1.18.2'
$zlibDir  = download_and_extract 'zlib-ng/zlib-ng/archive/refs/tags/2.2.2.zip'                   'zlib-ng-2.2.2'

function nmake_build([string]$dir, [string]$makefile, [string[]]$nmakeArgs) {
    Write-Host "Building ${dir}" -ForegroundColor Cyan

    Push-Location $dir
    try {
        exec { nmake.exe /nologo -f $makefile $nmakeArgs }
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

nmake_build $mathDir  "makefile.msvc" @()
nmake_build $cryptDir "makefile.msvc" @(
    "CFLAGS=/DUSE_LTM /DLTM_DESC ${endian_flags} /I${mathDir}"
    "EXTRALIBS=${mathDir}\tommath.lib"
)

$zlibMakefile = if ($HOST_MSVC_ARCH -eq "arm64") { 'win32/Makefile.a64' } else { 'win32/Makefile.msc' }
nmake_build $zlibDir $zlibMakefile @(
    "ZLIB_COMPAT=yes"
    "zlib.lib"
)

function make_bundle([string]$targetDir, [string]$headers, [string]$libs) {
    Write-Host "Bunding to ${targetDir}" -ForegroundColor Cyan

    remove_dir  "${targetDir}\include"
    create_dir  "${targetDir}\include"
    remove_file "${targetDir}\*.lib"

    Copy-Item "${headers}" "${targetDir}\include" -Force
    Copy-Item "${libs}"    "${targetDir}"         -Force
}

make_bundle "${ROOT_PATH}\Sources\libtommath-win"  "${mathDir}\*.h"              "${mathDir}\tommath.lib"
make_bundle "${ROOT_PATH}\Sources\libtomcrypt-win" "${cryptDir}\src\headers\*.h" "${cryptDir}\tomcrypt.lib"
make_bundle "${ROOT_PATH}\Sources\Z-win"           "${zlibDir}\*.h"              "${zlibDir}\zlib.lib"
