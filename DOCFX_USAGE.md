# DocFX Documentation Generation System

This repository contains a complete solution for generating and hosting API documentation from NuGet packages using DocFX.

## 🚀 Quick Start

### Prerequisites
- PowerShell 5.1 or later
- .NET SDK 8.0 or later
- NuGet CLI (optional, for package version updates)
- DocFX (installed automatically by scripts)

### Generate Documentation Locally

```powershell
# Option 1: Generate and serve locally in one command
.\scripts\Serve-Docs-Local.ps1

# Option 2: Generate only
.\scripts\Generate-Docs.ps1 -ConfigFile docs-config.json -OutputPath docs

# Option 3: Generate with clean rebuild
.\scripts\Generate-Docs.ps1 -ConfigFile docs-config.json -OutputPath docs -Clean
```

After running, the documentation will be available at: `http://localhost:8080`

## 📦 Configuration

Edit `docs-config.json` to configure which NuGet packages to document:

```json
{
  "packages": [
    {
      "id": "Microsoft.VisualStudio.Debugger.Engine",
      "version": "17.14.1051801",
      "description": "Visual Studio Debugger Engine APIs and interfaces",
      "framework": "net472"
    }
  ],
  "docfx": {
    "siteName": "Visual Studio Debugger Engine Documentation",
    "siteDescription": "API documentation for Visual Studio Debugger Engine extensibility interfaces",
    "baseUrl": "https://microsoft.github.io/ConcordExtensibilitySamples/"
  }
}
```

### Package Configuration Options
- **id**: NuGet package ID
- **version**: Specific version to document
- **description**: Human-readable description for the documentation
- **framework**: Target framework (e.g., "net472", "netstandard2.0")

## 🔄 Automatic Updates

### GitHub Actions
The repository includes a GitHub Action (`.github/workflows/docs.yml`) that:
- Runs automatically on pushes to main branch
- Runs weekly to pick up new package versions
- Can be triggered manually with force rebuild option
- Deploys to GitHub Pages automatically

### Package Version Updates
```powershell
# Check for updates (preview mode)
.\scripts\Update-PackageVersions.ps1 -Preview

# Update configuration file with latest versions
.\scripts\Update-PackageVersions.ps1
```

## 📁 Generated Structure

```
docs/
├── _site/              # Generated static website
├── api/                # Generated API reference (YAML files)
├── docfx.json         # DocFX configuration (auto-generated)
├── index.md           # Documentation homepage
└── toc.yml            # Table of contents
```

## 🌐 GitHub Pages Deployment

The documentation is automatically deployed to GitHub Pages at:
**https://microsoft.github.io/ConcordExtensibilitySamples/**

### Manual Deployment Setup
1. Go to repository Settings > Pages
2. Set Source to "GitHub Actions"
3. The workflow will handle the rest automatically

## 🛠️ Troubleshooting

### Common Issues

1. **DocFX not found**
   ```powershell
   dotnet tool install -g docfx
   ```

2. **NuGet package download fails**
   - Check package ID and version in `docs-config.json`
   - Ensure internet connectivity
   - Verify package exists on nuget.org

3. **Documentation generation fails**
   - Check that assemblies were extracted successfully
   - Verify .NET target framework compatibility
   - Review DocFX logs for specific errors

4. **GitHub Actions fails**
   - Check workflow permissions (Pages deployment requires write permissions)
   - Verify repository has GitHub Pages enabled
   - Review action logs for specific errors

### Debug Mode
Run scripts with verbose output:
```powershell
$VerbosePreference = "Continue"
.\scripts\Generate-Docs.ps1 -ConfigFile docs-config.json -Verbose
```

## 📋 Script Reference

### Generate-Docs.ps1
Main documentation generation script.

**Parameters:**
- `-ConfigFile`: Path to configuration JSON file (required)
- `-OutputPath`: Output directory for generated docs (default: "docs")
- `-Clean`: Remove existing files before generation

### Update-PackageVersions.ps1
Updates package versions in configuration to latest available.

**Parameters:**
- `-ConfigFile`: Path to configuration JSON file (default: "docs-config.json")
- `-Preview`: Show available updates without applying them

### Serve-Docs-Local.ps1
Generates and serves documentation locally for development.

**Parameters:**
- `-ConfigFile`: Path to configuration JSON file (default: "docs-config.json")
- `-Port`: Port for local web server (default: 8080)

## 🔧 Advanced Configuration

### Custom DocFX Templates
Modify the `template` array in the generated `docfx.json` to use custom templates:

```json
{
  "build": {
    "template": ["default", "modern", "custom-template-path"]
  }
}
```

### Multiple Package Sources
Add multiple packages to document different APIs:

```json
{
  "packages": [
    {
      "id": "Microsoft.VisualStudio.Debugger.Engine",
      "version": "17.14.1051801",
      "description": "Visual Studio Debugger Engine APIs",
      "framework": "net472"
    },
    {
      "id": "Microsoft.VisualStudio.Shell.Framework",
      "version": "17.0.31902.203", 
      "description": "Visual Studio Shell Framework",
      "framework": "net472"
    }
  ]
}
```

### Custom Metadata
Add custom metadata to generated documentation:

```json
{
  "docfx": {
    "siteName": "My API Docs",
    "siteDescription": "Documentation for my APIs",
    "baseUrl": "https://myorg.github.io/myrepo/",
    "customMetadata": {
      "_appFooter": "Copyright © 2025 My Organization",
      "_appLogoPath": "images/logo.png"
    }
  }
}
```

## 📝 License

This documentation system is part of the ConcordExtensibilitySamples repository and follows the same licensing terms.
