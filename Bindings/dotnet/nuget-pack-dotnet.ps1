#Requires -PSEdition Core -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandArgumentPassing = 'Standard'
$PSNativeCommandUseErrorActionPreference = $true
$PSStyle.OutputRendering = 'ANSI'

. $PSScriptRoot/nuget-utils.ps1

$PROJECT_DIR = Join-Path $REPO_ROOT 'Bindings/dotnet/RoyalApps.RoyalVNCKit' -Resolve

exec { dotnet build --configuration Release "-p:Version=${NUGET_VERSION}" $PROJECT_DIR }

$template = Get-Content "${PROJECT_DIR}/nuget/runtime.template.json" -Encoding utf8 -Raw
$template.Replace('"v"', "`"${NUGET_VERSION}`"") `
    | Set-Content "${PROJECT_DIR}/bin/Release/runtime.json" -Encoding utf8 -Force -NoNewline

Write-Host 'Creating RoyalApps.RoyalVNCKit  NuGet package'

exec {
    dotnet pack "${PROJECT_DIR}/RoyalApps.RoyalVNCKit.csproj" `
    "-p:NuspecFile=${PROJECT_DIR}/nuget/RoyalApps.RoyalVNCKit.nuspec" `
    "-p:NuspecBasePath=${PROJECT_DIR}" `
    "-p:NuspecProperties=`"NUGET_VERSION=${NUGET_VERSION};NUGET_GIT_COMMIT=${NUGET_GIT_COMMIT}`""
}
