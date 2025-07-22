<#
.SYNOPSIS
    Updates package versions in docs-config.json to latest available versions
.DESCRIPTION
    This script checks NuGet for the latest versions of configured packages and updates the configuration file
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "docs-config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Preview
)

$ErrorActionPreference = "Stop"

function Get-LatestPackageVersion {
    param([string]$PackageId)
    
    try {
        $nugetCmd = "nuget list $PackageId -NonInteractive"
        $result = Invoke-Expression $nugetCmd
        $line = $result | Where-Object { $_ -match "^$PackageId " } | Select-Object -First 1
        if ($line -match "$PackageId\s+(\d+\.\d+\.\d+(?:\.\d+)?)") {
            return $matches[1]
        }
    }
    catch {
        Write-Warning "Could not get latest version for $PackageId"
    }
    return $null
}

try {
    Write-Host "Checking for package updates..." -ForegroundColor Cyan
    
    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    $updated = $false
    
    foreach ($package in $config.packages) {
        Write-Host "Checking $($package.id)..." -ForegroundColor Yellow
        $latestVersion = Get-LatestPackageVersion $package.id
        
        if ($latestVersion -and $latestVersion -ne $package.version) {
            Write-Host "  Update available: $($package.version) -> $latestVersion" -ForegroundColor Green
            if (!$Preview) {
                $package.version = $latestVersion
                $updated = $true
            }
        } else {
            Write-Host "  Current version $($package.version) is up to date" -ForegroundColor Gray
        }
    }
    
    if ($updated) {
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile
        Write-Host "Configuration updated!" -ForegroundColor Green
    } elseif (!$Preview) {
        Write-Host "No updates needed" -ForegroundColor Gray
    }
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
