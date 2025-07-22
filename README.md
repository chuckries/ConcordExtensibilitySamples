# ConcordExtensibilitySamples

Visual Studio Debug Engine Extensibility Samples

## Documentation

📚 **[View API Documentation](https://microsoft.github.io/ConcordExtensibilitySamples/)** - Complete API documentation for Visual Studio Debugger Engine extensibility interfaces

### What are "Concord Extensibility Samples"?
[Concord](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Overview) is the code name for Visual Studio's new debug engine that first shipped in Visual Studio 2012. Concord was designed to be extensible and this repo contains samples of these extensions.

The samples in this repo currently target Visual Studio 2022 (version 17.0). For older versions of these samples, please see the [VS16 branch](https://github.com/Microsoft/ConcordExtensibilitySamples/tree/VS16).

### Getting started

For Concord documentation, take a look at the wiki:
* [Overview](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Overview)
* [Architecture](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Concord-Architecture)

If you want to dive right into some code for extending the debug engine, take a look at the samples:
* [Hello World](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Hello-World-Sample)
* [Managed Expression Evaluator](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Managed-Expression-Evaluator-Sample)
* [C++ Custom Visualizer](https://github.com/Microsoft/ConcordExtensibilitySamples/wiki/Cpp-Custom-Visualizer-Sample)

## Documentation Generation

This repository automatically generates and hosts API documentation for Visual Studio extensibility interfaces using DocFX. The documentation is built from NuGet packages and deployed to GitHub Pages.

### Local Development

To generate and serve documentation locally:

```powershell
# Generate and serve docs locally
.\scripts\Serve-Docs-Local.ps1

# Update package versions
.\scripts\Update-PackageVersions.ps1

# Generate docs only
.\scripts\Generate-Docs.ps1 -ConfigFile docs-config.json
```

### Configuration

Edit [`docs-config.json`](docs-config.json) to configure which NuGet packages to document.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
