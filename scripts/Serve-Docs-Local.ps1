<#
.SYNOPSIS
    Generates and serves documentation locally for development
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "docs-config.json",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "Starting local documentation server..." -ForegroundColor Cyan

try {
    # Generate docs
    & "./scripts/Generate-Docs.ps1" -ConfigFile $ConfigFile -OutputPath "docs" -Clean
    
    # Serve locally
    Push-Location "docs"
    Write-Host "Serving documentation at http://localhost:$Port" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    
    & docfx serve _site --port $Port
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
}
finally {
    Pop-Location
}
