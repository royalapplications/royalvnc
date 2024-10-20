#Requires -PSEdition Core -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

$SCRIPT_PATH = $PSScriptRoot
$ROOT_PATH = Join-Path $SCRIPT_PATH "..\.." -Resolve
Write-Host "Repo root: ${ROOT_PATH}"

$HOST_MSVC_ARCH = 'x64'
$HOST_LLVM_ARCH = 'x86_64'
if ($env:PROCESSOR_ARCHITECTURE -ieq 'ARM64') {
    $HOST_MSVC_ARCH = 'arm64'
    $HOST_LLVM_ARCH = 'aarch64'
}
Write-Host "CPU Arch: ${HOST_MSVC_ARCH} (MSVC), ${HOST_LLVM_ARCH} (LLVM/Swift)"


function exec([scriptblock]$command) {
    $nl_indent = [Environment]::NewLine + '    '
    $exec_clean_rx = [regex]::new('`\s*$\s+', [System.Text.RegularExpressions.RegexOptions]'Multiline,CultureInvariant,NonBacktracking,ExplicitCapture')
    
    $clean_command = $exec_clean_rx.Replace($command.ToString().Trim(), $nl_indent)
    $clean_command = ("@`"`n$clean_command`n`"@" | Invoke-Expression)

    Write-Host $clean_command -ForegroundColor cyan
    Invoke-Command -ScriptBlock $command

    if ($lastexitcode -ne 0) { throw $lastexitcode }
}

function create_dir([string]$path) {
    if (-not (Test-Path $path -PathType Container)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
}

function dir_exists([string]$path) {
    return Test-Path $path -PathType Container
}

function file_exists([string]$path) {
    return Test-Path $path -PathType Leaf
}

function remove_dir([string]$path) {
    if (dir_exists $path) {
		Remove-Item $path -Recurse -Force
	}
}

function remove_file([string]$path) {
    if (file_exists $path) {
        Remove-Item $path -Force
    }
}