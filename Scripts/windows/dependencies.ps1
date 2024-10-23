#Requires -PSEdition Core -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

. $PSScriptRoot\utils.ps1

$cmake = (Get-Command cmake.exe -ErrorAction Stop)
$ninja = (Get-Command ninja.exe -ErrorAction Stop)
$nmake = (Get-Command nmake.exe -ErrorAction Stop)
$swift = (Get-Command swift.exe -ErrorAction Stop)

$cmake,$ninja,$nmake,$swift | Format-Table -AutoSize -HideTableHeaders -Property Source 

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

$mathDir  = download_and_extract 'libtom/libtommath/releases/download/v1.3.0/ltm-1.3.0.zip'      'libtommath-1.3.0'
$cryptDir = download_and_extract 'libtom/libtomcrypt/releases/download/v1.18.2/crypt-1.18.2.zip' 'libtomcrypt-1.18.2'
$zlibDir  = download_and_extract 'zlib-ng/zlib-ng/archive/refs/tags/2.2.2.zip'                   'zlib-ng-2.2.2'

function nmake_build([string]$dir, [string]$makefile, [string[]]$nmakeArgs) {
    Write-Host "Building ${dir} with nmake" -ForegroundColor Cyan
    
    Push-Location $dir
    try {
        exec { nmake.exe /nologo -f $makefile  $nmakeArgs "" }
    } finally {
        Pop-Location
    }
}

[string]$cryptArm64flags = ''
if ($HOST_MSVC_ARCH -eq 'arm64') { 
    # Needed because the endian detection macros do not work on arm64 in a released version.
    # This is now fixed but no new release was made since. Avoid warnings on x64 by not overriding there.
    # ref. https://github.com/libtom/libtomcrypt/commit/c4d22b904604f2f49c717ffc9bf86678658117b0#diff-2db5eece44c5b2ec42c2e2a08d847e6b0e3723d7d11bf7d5bda16f20fe795ff9R83
    $cryptArm64flags = '/DENDIAN_LITTLE /DENDIAN_64BITWORD /DLTC_FAST'
}

[string]$BUNDLE_DIR = "${BIN_DIR}\deps-windows"
clean_dir $BUNDLE_DIR

nmake_build $mathDir  "makefile.msvc" @(
    "PREFIX=${BUNDLE_DIR}"
    'install'
)
nmake_build $cryptDir "makefile.msvc" @(
    "CFLAGS=/DUSE_LTM /DLTM_DESC ${cryptArm64flags} /I${mathDir}"
    "EXTRALIBS=${mathDir}\tommath.lib"
    "PREFIX=${BUNDLE_DIR}"
    'install'
)

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
