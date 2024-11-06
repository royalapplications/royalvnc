#Requires -PSEdition Core -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandArgumentPassing = 'Standard'
$PSNativeCommandUseErrorActionPreference = $true
$PSStyle.OutputRendering = 'ANSI'

. $PSScriptRoot/nuget-utils.ps1

$PROJECT_DIR = Join-Path $REPO_ROOT 'Bindings/dotnet/RoyalApps.RoyalVNCKit' -Resolve

exec { dotnet build --configuration Release "-p:Version=${NUGET_VERSION}" $PROJECT_DIR }

Write-Host 'Creating RoyalApps.RoyalVNCKit  NuGet package'

exec {
    dotnet pack "${PROJECT_DIR}/RoyalApps.RoyalVNCKit.csproj" `
    "-p:NuspecFile=${PROJECT_DIR}/nuget/RoyalApps.RoyalVNCKit.nuspec" `
    "-p:NuspecBasePath=${PROJECT_DIR}" `
    "-p:NuspecProperties=`"NUGET_VERSION=${NUGET_VERSION};NUGET_GIT_COMMIT=${NUGET_GIT_COMMIT}`""
}
