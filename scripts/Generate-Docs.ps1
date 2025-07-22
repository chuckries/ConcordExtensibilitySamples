<#
.SYNOPSIS
    Generates DocFX documentation from NuGet packages
.DESCRIPTION
    This script downloads specified NuGet packages, extracts assemblies, and generates DocFX documentation
.PARAMETER ConfigFile
    Path to the configuration JSON file
.PARAMETER OutputPath
    Output path for generated documentation
.PARAMETER Clean
    Clean existing files before generation
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "docs",
    
    [Parameter(Mandatory = $false)]
    [switch]$Clean
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Color
}

# Function to get latest package version from NuGet
function Get-LatestPackageVersion {
    param([string]$PackageId)
    
    try {
        Write-ColorOutput "  Resolving latest version for $PackageId..." "Gray"
        
        # Try using dotnet package search first
        $searchResult = & dotnet package search $PackageId --exact-match --format json 2>$null
        if ($LASTEXITCODE -eq 0 -and $searchResult) {
            $jsonResult = $searchResult | ConvertFrom-Json
            if ($jsonResult.searchResult -and $jsonResult.searchResult.Count -gt 0) {
                $latestVersion = $jsonResult.searchResult[0].latestVersion
                if ($latestVersion) {
                    Write-ColorOutput "  Found latest version: $latestVersion" "Gray"
                    return $latestVersion
                }
            }
        }
        
        # Fallback: Try using NuGet CLI if available
        if (Get-Command "nuget" -ErrorAction SilentlyContinue) {
            $nugetResult = & nuget list $PackageId -NonInteractive 2>$null
            if ($LASTEXITCODE -eq 0 -and $nugetResult) {
                $line = $nugetResult | Where-Object { $_ -match "^$PackageId " } | Select-Object -First 1
                if ($line -match "$PackageId\s+(\d+\.\d+\.\d+(?:\.\d+)?)") {
                    $latestVersion = $matches[1]
                    Write-ColorOutput "  Found latest version: $latestVersion" "Gray"
                    return $latestVersion
                }
            }
        }
        
        # Final fallback: Use NuGet API
        $apiUrl = "https://api.nuget.org/v3-flatcontainer/$($PackageId.ToLower())/index.json"
        $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction SilentlyContinue
        if ($response -and $response.versions) {
            $latestVersion = $response.versions | Sort-Object { [System.Version]$_ } | Select-Object -Last 1
            Write-ColorOutput "  Found latest version: $latestVersion" "Gray"
            return $latestVersion
        }
    }
    catch {
        Write-ColorOutput "  Warning: Could not resolve latest version for $PackageId - $_" "Yellow"
    }
    
    return $null
}

# Function to ensure directory exists
function Ensure-Directory {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Function to resolve package version (handle "latest" keyword)
function Resolve-PackageVersion {
    param(
        [string]$PackageId,
        [string]$Version
    )
    
    if ($Version -eq "latest") {
        $resolvedVersion = Get-LatestPackageVersion $PackageId
        if ($resolvedVersion) {
            return $resolvedVersion
        } else {
            throw "Could not resolve latest version for package: $PackageId"
        }
    } else {
        return $Version
    }
}

# Main script
try {
    Write-ColorOutput "Starting DocFX documentation generation..." "Cyan"
    
    # Load configuration
    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-ColorOutput "Loaded configuration with $($config.packages.Count) packages"
    
    # Setup directories
    $tempDir = Join-Path $env:TEMP "docfx-nuget-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $packagesDir = Join-Path $tempDir "packages"
    $assembliesDir = Join-Path $tempDir "assemblies"
    
    Ensure-Directory $tempDir
    Ensure-Directory $packagesDir
    Ensure-Directory $assembliesDir
    Ensure-Directory $OutputPath
    
    Write-ColorOutput "Working directory: $tempDir" "Yellow"
    
    # Clean output if requested
    if ($Clean) {
        Write-ColorOutput "Cleaning existing documentation..." "Yellow"
        Remove-Item (Join-Path $OutputPath "*") -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Download and extract packages
    Write-ColorOutput "Downloading NuGet packages..." "Cyan"
    
    $assemblies = @()
    $resolvedPackages = @()
    foreach ($package in $config.packages) {
        # Resolve version (handle "latest" keyword)
        $resolvedVersion = Resolve-PackageVersion $package.id $package.version
        Write-ColorOutput "Processing package: $($package.id) v$resolvedVersion"
        
        # Track resolved package info for documentation
        $resolvedPackages += @{
            id = $package.id
            originalVersion = $package.version
            resolvedVersion = $resolvedVersion
            description = $package.description
        }
        
        # First check if package is already in global cache
        $globalPackagePath = Join-Path $env:USERPROFILE ".nuget\packages\$($package.id.ToLower())\$resolvedVersion"
        $packageDir = $null
        
        if (Test-Path $globalPackagePath) {
            Write-ColorOutput "  Found in global NuGet cache: $globalPackagePath" "Gray"
            $packageDir = $globalPackagePath
        } else {
            # Download package using nuget install
            $nugetArgs = @(
                "install", $package.id,
                "-Version", $resolvedVersion,
                "-OutputDirectory", $packagesDir,
                "-NoCache",
                "-NonInteractive"
            )
            
            & nuget @nugetArgs
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to download package: $($package.id)"
            }
            
            $packageDir = Join-Path $packagesDir "$($package.id).$resolvedVersion"
        }
        
        if (!(Test-Path $packageDir)) {
            throw "Package directory not found: $packageDir"
        }
        
        
        # Find and copy assemblies from lib or ref folders
        $libDir = Join-Path $packageDir "lib"
        $refDir = Join-Path $packageDir "ref"
        
        # Try lib folder first, then ref folder
        $searchDirs = @()
        if (Test-Path $libDir) { $searchDirs += $libDir }
        if (Test-Path $refDir) { $searchDirs += $refDir }
        
        if ($searchDirs.Count -eq 0) {
            Write-ColorOutput "  Warning: No lib or ref directories found in package" "Yellow"
            continue
        }
        
        foreach ($searchDir in $searchDirs) {
            Write-ColorOutput "  Searching in: $searchDir" "Gray"
            
            # Find appropriate framework folder
            $frameworkDir = $null
            if ($package.framework) {
                $frameworkDir = Join-Path $searchDir $package.framework
                # Also try common variations
                if (!(Test-Path $frameworkDir)) {
                    $variations = @("netstandard2.0", "net462", "net472", "net48")
                    foreach ($variation in $variations) {
                        $testPath = Join-Path $searchDir $variation
                        if (Test-Path $testPath) {
                            $frameworkDir = $testPath
                            break
                        }
                    }
                }
            }
            
            if (!$frameworkDir -or !(Test-Path $frameworkDir)) {
                # Find the best available framework
                $availableFrameworks = Get-ChildItem $searchDir -Directory | Sort-Object Name -Descending
                if ($availableFrameworks.Count -gt 0) {
                    $frameworkDir = $availableFrameworks[0].FullName
                }
            }
            
            if ($frameworkDir -and (Test-Path $frameworkDir)) {
                Write-ColorOutput "  Using framework directory: $frameworkDir" "Gray"
                
                # Copy DLL files
                $dllFiles = Get-ChildItem $frameworkDir -Filter "*.dll"
                foreach ($dll in $dllFiles) {
                    $destPath = Join-Path $assembliesDir $dll.Name
                    Copy-Item $dll.FullName $destPath -Force
                    $assemblies += $destPath
                    Write-ColorOutput "  Copied: $($dll.Name)" "Gray"
                    
                    # Copy corresponding XML documentation file if it exists
                    $xmlName = [System.IO.Path]::ChangeExtension($dll.Name, ".xml")
                    $xmlPath = Join-Path $frameworkDir $xmlName
                    if (Test-Path $xmlPath) {
                        $xmlDestPath = Join-Path $assembliesDir $xmlName
                        Copy-Item $xmlPath $xmlDestPath -Force
                        Write-ColorOutput "  Copied: $xmlName" "Gray"
                    }
                }
                break # Found assemblies, no need to check other directories
            }
        }
    }
    
    if ($assemblies.Count -eq 0) {
        throw "No assemblies found in downloaded packages"
    }
    
    Write-ColorOutput "Found $($assemblies.Count) assemblies to document" "Green"
    
    # Generate DocFX configuration
    Write-ColorOutput "Generating DocFX configuration..." "Cyan"
    
    $docfxConfig = @{
        metadata = @(
            @{
                src = @(
                    @{
                        files = $assemblies | ForEach-Object { [System.IO.Path]::GetFileName($_) }
                        src = $assembliesDir
                    }
                )
                dest = "api"
                includePrivateMembers = $false
                disableGitFeatures = $false
                disableDefaultFilter = $false
                allowCompilationErrors = $true
                properties = @{
                    TargetFramework = "netstandard2.0"
                }
                filter = "filterConfig.yml"
            }
        )
        build = @{
            content = @(
                @{
                    files = @(
                        "api/**.yml",
                        "api/index.md"
                    )
                },
                @{
                    files = @(
                        "articles/**.md",
                        "articles/**/toc.yml",
                        "toc.yml",
                        "*.md"
                    )
                }
            )
            resource = @(
                @{
                    files = @("images/**")
                }
            )
            output = "_site"
            template = @("default", "modern")
            globalMetadata = @{
                "_appName" = $config.docfx.siteName
                "_appTitle" = $config.docfx.siteDescription
                "_enableSearch" = $true
                "_gitContribute" = @{
                    repo = "https://github.com/microsoft/ConcordExtensibilitySamples"
                    branch = "main"
                }
                "_gitUrlPattern" = "github"
                "_disableContribution" = $true
            }
        }
    }
    
    $docfxConfigPath = Join-Path $OutputPath "docfx.json"
    $docfxConfig | ConvertTo-Json -Depth 10 | Set-Content $docfxConfigPath
    
    # Create a filter configuration to include all public APIs
    $filterConfig = @"
apiRules:
- exclude:
    uidRegex: ^System\.
    type: Namespace
- exclude:
    uidRegex: ^Microsoft\.VisualStudio\..*\.Internal
    type: Namespace
- include:
    uidRegex: .*
    type: Type
- include:
    uidRegex: .*
    type: Member
"@
    
    Set-Content (Join-Path $OutputPath "filterConfig.yml") $filterConfig
    
    # Create index page
    $packageList = $resolvedPackages | ForEach-Object { 
        $nugetUrl = "https://www.nuget.org/packages/$($_.id)/$($_.resolvedVersion)"
        if ($_.originalVersion -eq "latest") {
            "- **$($_.id)** [v$($_.resolvedVersion)]($nugetUrl) (latest) - $($_.description)"
        } else {
            "- **$($_.id)** [v$($_.resolvedVersion)]($nugetUrl) - $($_.description)"
        }
    } | Out-String
    
    $indexContent = @"
# $($config.docfx.siteName)

$($config.docfx.siteDescription)

## API Documentation

This documentation covers the following packages:

$packageList

## API Reference

Use the navigation menu above to browse the API Reference for detailed documentation of all types and members.

---

*Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC') from NuGet packages*
"@
    
    Set-Content (Join-Path $OutputPath "index.md") $indexContent
    
    # Create table of contents
    $tocContent = @"
- name: Home
  href: index.md
- name: API Reference
  href: api/
"@
    
    Set-Content (Join-Path $OutputPath "toc.yml") $tocContent
    
    # Create articles directory and basic content
    $articlesDir = Join-Path $OutputPath "articles"
    Ensure-Directory $articlesDir
    
    # Generate documentation
    Write-ColorOutput "Generating documentation with DocFX..." "Cyan"
    
    Push-Location $OutputPath
    try {
        & docfx docfx.json
        if ($LASTEXITCODE -ne 0) {
            throw "DocFX generation failed"
        }
        
        Write-ColorOutput "Documentation generated successfully!" "Green"
        Write-ColorOutput "Output directory: $(Join-Path (Get-Location) '_site')" "Yellow"
    }
    finally {
        Pop-Location
    }
    
    # Cleanup
    Write-ColorOutput "Cleaning up temporary files..." "Yellow"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-ColorOutput "Documentation generation completed successfully!" "Green"
}
catch {
    Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
    if ($tempDir -and (Test-Path $tempDir)) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 1
}
