<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Automates npm package installation from a PACKAGES file with version
    management and dependency resolution.

.DESCRIPTION
    This script processes a PACKAGES file to install and manage npm
    dependencies consistently across development environments. It parses package
    specifications, resolves versions, enforces exact version locking
    (--save-exact), and provides comprehensive progress and error reporting.

    The workflow includes parsing, version resolution, installation, and a
    final security audit fix pass performed across all discovered package
    directories using npm's --prefix flag. It emphasizes reliability with clear
    progress feedback and graceful error recovery. Requires local helper modules
    (concise-log.psm1 and powershell-core.psm1) loaded from the scripts directory.

.NOTES
    Author: npm-package-setup automation
    Version: 0.0.0
    Last Modified: 2026-02-16
    Platform: Windows only
    Requirements: pwsh 7.5.4, npm, node, package.json

.EXAMPLE
    # Processes the default PACKAGES file and installs all specified packages.
    .\setup-npm-packages.ps1

.EXIT CODES
    0 - Success (all packages processed, may have individual failures)
    1 - Fatal error (missing prerequisites, file not found, etc.)
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Import required modules
# Derives module paths from the script directory to resolve local modules.
$scriptPath = $PSScriptRoot
$conciseLogPath = Join-Path $scriptPath 'concise-log.psm1'
$coreModulePath = Join-Path $scriptPath 'powershell-core.psm1'

# Convert to absolute paths (REQUIRED)
# Absolute paths avoid ambiguity when invoked from different working dirs.
$conciseLogPath = [System.IO.Path]::GetFullPath($conciseLogPath)
$coreModulePath = [System.IO.Path]::GetFullPath($coreModulePath)

if (-not (Test-Path -LiteralPath $conciseLogPath)) {
    Write-Error 'Required module not found: concise-log.psm1'

    exit 1
}

if (-not (Test-Path -LiteralPath $coreModulePath)) {
    Write-Error 'Required module not found: powershell-core.psm1'

    exit 1
}

# Explicit import order: concise-log first, powershell-core second.
Import-Module -Name $conciseLogPath -Force -ErrorAction Stop
Import-Module -Name $coreModulePath -Force -ErrorAction Stop

# Function to get the packages file path
function Get-PackagesFilePath {
    <#
    .SYNOPSIS
        Dynamically determines the path to the PACKAGES file.

    .DESCRIPTION
        Returns the path to the PACKAGES file based on the current working
        directory. The file is expected to be named "PACKAGES" and located in
        the current directory.

    .OUTPUTS
        System.String. The absolute path to the PACKAGES file.

    .EXAMPLE
        $packagesFilePath = Get-PackagesFilePath
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $packagesFilePath = [System.IO.Path]::GetFullPath(
        (Join-Path $PWD.Path 'PACKAGES')
    )

    if (-not (Test-Path -LiteralPath $packagesFilePath -PathType Leaf)) {
        Write-ErrorLog -Scope "PACKAGES-FILE" `
            -Message "PACKAGES file not found: $packagesFilePath"

        throw "PACKAGES file not found: $packagesFilePath"
    }

    return $packagesFilePath
}

#region Prerequisites Validation Functions

function Test-NpmAvailable {
    <#
    .SYNOPSIS
        Tests if npm command is available in the system PATH.

    .DESCRIPTION
        Validates that the npm command can be found and executed. This is a
        prerequisite for all package installation operations. Provides detailed
        error information for troubleshooting.

    .OUTPUTS
        System.Boolean. Returns $true if npm is available, $false otherwise.

    .EXAMPLE
        if (Test-NpmAvailable) {
            Write-InfoLog -Scope "NPM-CHECK" -Message "npm is available"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        Write-InfoLog -Scope "NPM-CHECK" -Message "Checking npm availability"

        # Uses call operator (&) to invoke npm and trims newline characters.
        # Version format MUST be MAJOR.MINOR.PATCH (e.g., 10.4.1).
        $npmVersion = (& npm --version).Trim()

        Write-InfoLog -Scope "NPM-CHECK" `
            -Message "npm version: $npmVersion"

        if (-not $npmVersion -or $npmVersion -notmatch '^\d+\.\d+\.\d+$') {
            return $false
        }

        return $true

    } catch {
        Write-ErrorLog -Scope "NPM-CHECK" `
            -Message "npm availability check failed: $($_.Exception.Message)"

        return $false
    }
}

function Test-NodeAvailable {
    <#
    .SYNOPSIS
        Tests if node command is available in the system PATH.

    .DESCRIPTION
        Validates that the node command can be found and executed.
        Node.js is required for npm package management operations.
        Provides detailed error information for troubleshooting.

    .OUTPUTS
        System.Boolean. Returns $true if node is available, $false otherwise.

    .EXAMPLE
        if (Test-NodeAvailable) {
            Write-InfoLog -Scope "NODE-CHECK" -Message "Node.js is available"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        Write-InfoLog -Scope "NODE-CHECK" -Message "Checking node availability"

        # Node prints versions like "v22.12.0"; remove leading "v" and
        # validate against MAJOR.MINOR.PATCH numeric pattern.
        $nodeVersion = ((& node --version).Trim() -split 'v')[-1]

        Write-InfoLog -Scope "NODE-CHECK" `
            -Message "Node.js version: $nodeVersion"

        if (-not $nodeVersion -or $nodeVersion -notmatch '^\d+\.\d+\.\d+$') {
            return $false
        }

        return $true

    } catch {
        Write-ErrorLog -Scope "NODE-CHECK" `
            -Message "Node availability check failed: $($_.Exception.Message)"

        return $false
    }
}

function Test-PackageJsonExists {
    <#
    .SYNOPSIS
        Tests if package.json exists in the current directory.

    .DESCRIPTION
        Validates that a package.json file exists in the current working
        directory. This file is required for npm package installations.
        Provides detailed path information for troubleshooting.

    .OUTPUTS
        System.Boolean. Returns $true if package.json exists, $false otherwise.

    .EXAMPLE
        if (Test-PackageJsonExists) {
            Write-InfoLog -Scope "PKG-JSON" -Message "package.json found"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        Write-InfoLog -Scope "PKG-JSON" `
            -Message "Checking package.json availability"

        # Build absolute path to package.json in the current directory.
        $packageJsonPath = [System.IO.Path]::GetFullPath(
            (Join-Path $PWD.Path 'package.json')
        )

        return (Test-Path -LiteralPath $packageJsonPath -PathType Leaf)

    } catch {
        Write-ErrorLog -Scope "PKG-JSON" `
            -Message "package.json check failed: $($_.Exception.Message)"

        return $false
    }
}

function Test-PackagesFileExists {
    <#
    .SYNOPSIS
        Tests if the PACKAGES file exists at the specified path.

    .DESCRIPTION
        Validates that the PACKAGES file exists and is accessible for reading.
        This is a prerequisite for processing package specifications.
        Provides detailed path information for troubleshooting.

    .OUTPUTS
        System.Boolean. Returns $true if file exists, $false otherwise.

    .EXAMPLE
        if (Test-PackagesFileExists) {
            Write-InfoLog -Scope "FILE-CHECK" -Message "PACKAGES file found"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $packagesFilePath = [System.IO.Path]::GetFullPath(
            (Join-Path $PWD.Path 'PACKAGES')
        )

        Write-InfoLog -Scope "FILE-CHECK" `
            -Message "Checking PACKAGES file availability at: $packagesFilePath"

        return (Test-Path -LiteralPath $packagesFilePath -PathType Leaf)

    } catch {
        Write-ErrorLog -Scope "FILE-CHECK" `
            -Message "PACKAGES file check failed: $($_.Exception.Message)"

        return $false
    }
}
function Assert-Prerequisites {
    <#
    .SYNOPSIS
        Validates all prerequisites for npm package setup.

    .DESCRIPTION
        Performs comprehensive validation of all required prerequisites
        including npm, node, and package.json. Provides detailed error
        messages with troubleshooting guidance and exits gracefully
        with error code 1 if any prerequisite is missing.

    .EXAMPLE
        # Validates all prerequisites and exits on failure.
        Assert-Prerequisites
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "PREREQ-START" `
        -Message "Validating prerequisites for npm package setup"

    if (-not (Test-NpmAvailable)) {
        Write-WarningLog -Scope "PREREQ-FAIL" `
            -Message ("Command npm is not available. " +
                "Please install Node.js and npm" +
                "Ensure they are in your PATH.")

        throw "Prerequisite check failed: npm is not available"
    }

    if (-not (Test-NodeAvailable)) {
        Write-WarningLog -Scope "PREREQ-FAIL" `
            -Message ("Command node is not available. " +
                "Please install Node.js" +
                "Ensure they are in your PATH.")

        throw "Prerequisite check failed: node is not available"
    }

    if (-not (Test-PackageJsonExists)) {
        Write-WarningLog -Scope "PREREQ-FAIL" `
            -Message ("package.json not found in current directory. " +
                "Please run 'npm init' to create a package.json file " +
                "or navigate to a directory that contains one.")

        throw "Prerequisite check failed: package.json not found"
    }

    if (-not (Test-PackagesFileExists)) {
        Write-WarningLog -Scope "PREREQ-FAIL" `
            -Message ("PACKAGES file not found in current directory. " +
                "Please ensure the file exists in the current directory.")

        throw "Prerequisite check failed: PACKAGES file not found"
    }

    Write-InfoLog -Scope "PREREQ-PASS" `
        -Message "All prerequisites validated successfully"
}

#endregion

#region PACKAGES File Processing Functions

function Read-PackagesFile {
    <#
    .SYNOPSIS
        Reads and processes the PACKAGES file line by line.

    .DESCRIPTION
        Reads the PACKAGES file and processes each line sequentially, skipping
        empty lines and comment lines (starting with #). Returns an array of
        non-empty, non-comment lines for further processing. Implements
        comprehensive error handling for file access issues.

    .OUTPUTS
        System.String[]. Array of package specification lines.

    .EXAMPLE
        $packageLines = Read-PackagesFile
        foreach ($line in $packageLines) {
            # Process each package specification
        }
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    try {
        $packagesFilePath = Get-PackagesFilePath

        Write-InfoLog -Scope "FILE-READ" `
            -Message "Reading PACKAGES file from: $packagesFilePath"

        $lineList = Get-Content -LiteralPath $packagesFilePath -ErrorAction Stop
        $packageLineList = @()

        if ($lineList -is [string]) {
            $lineList = @($lineList)
        }

        foreach ($line in $lineList) {
            $line = $line.Trim()

            # Skip blank lines and comment lines (starting with "#").
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            if ($line.StartsWith('#')) {
                continue
            }

            $packageLineList += $line
        }

        # Unary comma ensures array return even for a single line.
        return ,$packageLineList

    } catch {
        Write-ErrorLog -Scope "FILE-READ" `
            -Message "Error reading PACKAGES file: $($_.Exception.Message)"

        throw "Failed to read PACKAGES file: $($_.Exception.Message)"
    }
}

#endregion

#region Package Specification Parsing Functions

function ConvertFrom-PackageSpecification {
    <#
    .SYNOPSIS
        Converts a package specification line into structured data.

    .DESCRIPTION
        Extracts package name, version constraint, and installation flags from a
        package specification line. Handles @version syntax for explicit version
        constraints and --save/--save-dev flags for dependency type specification.

        Supported formats:
        - package-name
        - package-name@1.2.3
        - package-name --save-dev
        - package-name@1.2.3 --save-dev
        - @scoped/package-name
        - @scoped/package-name@1.2.3 --save

    .PARAMETER Line
        The package specification line to parse.

    .OUTPUTS
        System.Management.Automation.PSCustomObject. Returns object with
        Name, Version, Flags, and OriginalLine properties.

    .EXAMPLE
        # Returns: Name="lodash", Version="4.17.21", Flags=@("--save-dev")
        $spec = ConvertFrom-PackageSpecification -Line "lodash@4.17.21 --save-dev"

    .EXAMPLE
        # Returns: Name="@types/node", Version=$null, Flags=@()
        $spec = ConvertFrom-PackageSpecification -Line "@types/node"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Package specification line")]
        [ValidateNotNullOrEmpty()]
        [string]$Line
    )

    try {
        # Tokenization: split by whitespace, remove empties.
        # First token: "name", "name@version", or "@scope/name[@version]".
        # Remaining tokens are candidate flags (e.g., --save-dev).
        $packageData = [PSCustomObject]@{
            Name = $null
            Version = $null
            Flags = @()
            Line = $Line.Trim()
        }

        $tokenList = @($Line.Trim() -split '\s+' | Where-Object { $_ -ne '' })

        $packageAndVersion = $tokenList[0]
        if ($packageAndVersion.StartsWith('@')) {
            $versionIndex = $packageAndVersion.IndexOf('@', 1)

            if ($versionIndex -gt 0) {
                $packageData.Name = $packageAndVersion.Substring(0, $versionIndex)
                $packageData.Version = $packageAndVersion.Substring(
                    $versionIndex + 1
                )
            } else {
                $packageData.Name = $packageAndVersion
                $packageData.Version = $null
            }
        } else {
            $versionIndex = $packageAndVersion.IndexOf('@')
            if ($versionIndex -gt 0) {
                $packageData.Name = $packageAndVersion.Substring(0, $versionIndex)
                $packageData.Version = $packageAndVersion.Substring(
                    $versionIndex + 1
                )
            } else {
                $packageData.Name = $packageAndVersion
                $packageData.Version = $null
            }
        }

        $flagList = @()
        if ($tokenList.Count -gt 1) {
            $flagList = $tokenList[1..($tokenList.Count - 1)]
        }

        $validFlags = @()

        for ($index = 0; $index -lt $flagList.Count; $index++) {
            $flag = $flagList[$index]
            switch ($flag) {
                '--save' {
                    $validFlags += '--save'
                }
                '--save-dev' {
                    $validFlags += '--save-dev'
                }
                default {
                    if ($flag -eq '--prefix') {
                        if ($index + 1 -lt $flagList.Count) {
                            $prefixValue = $flagList[$index + 1]
                            $validFlags += '--prefix'
                            $validFlags += $prefixValue
                            $index++
                        } else {
                            Write-ErrorLog -Scope "PARSE-SPEC" `
                                -Message "Flag --prefix missing value: $Line"

                            throw ("Failed to parse package specification: " +
                                "'$Line' - Flag --prefix missing value")
                        }
                    }
                }
            }
        }

        $packageData.Flags = $validFlags

        return $packageData

    } catch {
        Write-ErrorLog -Scope "PARSE-SPEC" `
            -Message ("Error parsing package specification: " +
                "'$Line' - $($_.Exception.Message)")

        throw ("Failed to parse package specification: " +
            "'$Line' - $($_.Exception.Message)")
    }
}

#endregion

#region Version Resolution Functions

function Get-LatestStableVersion {
    <#
    .SYNOPSIS
        Queries npm registry to get the latest stable version of a package.

    .DESCRIPTION
        Retrieves the latest stable version of an npm package from the registry
        using npm view command. Returns null on failure.

    .PARAMETER PackageName
        Name of the npm package to query for latest version.

    .OUTPUTS
        System.String. Returns version string (e.g., "1.2.3") or $null on failure.

    .EXAMPLE
        # Returns: "4.17.21" (or current latest version)
        $version = Get-LatestStableVersion -PackageName "lodash"

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Package name to query")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName
    )

    try {
        # Queries npm registry for "version" field and trims whitespace.
        $version = (& npm view $PackageName version).Trim()

        if (-not $version -or $version -notmatch '^\d+\.\d+\.\d+$') {
            return $null
        }

        Write-InfoLog -Scope "VERSION-QUERY" `
            -Message "Latest stable version for '$PackageName': $version"

        return $version

    } catch {
        Write-WarningLog -Scope "VERSION-QUERY" `
            -Message "Query failed for '$PackageName': $($_.Exception.Message)"

        # Offline/registry errors return $null; caller handles resolution.
        return $null
    }
}

#endregion

#region Package Installation Functions

function Install-NpmPackage {
    <#
    .SYNOPSIS
        Installs an npm package with proper flag handling and error management.

    .DESCRIPTION
        Executes npm install command for a specific package with version and flags.
        Implements working directory management, --save-exact flag enforcement,
        and comprehensive error handling with continuation on failures.
        Provides detailed logging of installation progress and outcomes.

    .PARAMETER PackageName
        Name of the npm package to install.

    .PARAMETER Version
        Specific version to install. If null, installs latest available.

    .PARAMETER Flags
        Array of installation flags (--save, --save-dev, etc.).

    .EXAMPLE
        # Installs lodash@4.17.21 as dev dependency with --save-exact
        $result = Install-NpmPackage -PackageName "lodash" -Version "4.17.21" `
            -Flags @("--save-dev")

    .EXAMPLE
        # Installs latest @types/node as dev dependency with --save-exact
        $result = Install-NpmPackage -PackageName "@types/node" `
            -Version "18.19.39" `
            -Flags @("--save-dev")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Package name to install")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName,

        [Parameter(Mandatory = $false,
            HelpMessage = "Package version to install")]
        [AllowNull()]
        [string]$Version,

        [Parameter(Mandatory = $false,
            HelpMessage = "Installation flags")]
        [ValidateNotNull()]
        [string[]]$Flags = @()
    )

    $targetPackage = $PackageName

    if ($Version) {
        $targetPackage = "$PackageName@$Version"
    }

    try {
        Write-InfoLog -Scope "INSTALL-PKG" `
            -Message "Installing $targetPackage"

        & npm install $targetPackage --save-exact $Flags

        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog -Scope "INSTALL-PKG" `
                -Message "Installed $targetPackage"
        } else {
            Write-WarningLog -Scope "INSTALL-PKG" `
                -Message "Install failed ($LASTEXITCODE): $targetPackage"
        }

    } catch {
        Write-WarningLog -Scope "INSTALL-PKG" `
            -Message ("Error during $targetPackage package installation: " +
                "$($_.Exception.Message)")

        throw ("Failed to install $($targetPackage): " +
            "$($_.Exception.Message)")
    }
}

function Get-PackageLockDirectoriesWithPackageJson {
    <#
    .SYNOPSIS
        Returns directories containing both package-lock.json and package.json.

    .DESCRIPTION
        Scans the current working directory recursively for package-lock.json
        files, excludes results under node_modules, and returns a unique list of
        directories that also contain package.json.

    .OUTPUTS
        System.String[]. Unique absolute directory paths.

    .EXAMPLE
        # Returns: @("C:\project1", "C:\project2\subdir")
        $directoryList = Get-PackageLockDirectoriesWithPackageJson

    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    try {
        Write-InfoLog -Scope "PKGLOCK-SCAN" `
            -Message "Scanning directories for package-lock.json and package.json"

        $directoryList = Get-ChildItem -Path $PWD.Path -Recurse -File `
            -Filter 'package-lock.json' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]+node_modules[\\/]+' } |
            Select-Object -ExpandProperty DirectoryName |
            Sort-Object -Unique

        $validDirectoryList = @()

        foreach ($directory in $directoryList) {
            $packageJSONPath = [System.IO.Path]::GetFullPath(
                (Join-Path $directory 'package.json')
            )

            if (Test-Path -LiteralPath $packageJSONPath -PathType Leaf) {
                $validDirectoryList += $directory
            }
        }

        return ,$validDirectoryList

    } catch {
        Write-ErrorLog -Scope "PKGLOCK-SCAN" `
            -Message "Error scanning directories: $($_.Exception.Message)"

        throw "Failed to discover directories: $($_.Exception.Message)"
    }
}

function Invoke-NpmAuditFix {
    <#
    .SYNOPSIS
        Executes npm audit fix across discovered package directories.

    .DESCRIPTION
        Discovers directories containing both package-lock.json and package.json
        via Get-PackageLockDirectoriesWithPackageJson, then runs npm audit fix
        for each directory using the --prefix flag. Handles failures per-directory
        without terminating the script.

    .EXAMPLE
        # Runs npm audit fix for each discovered directory using --prefix
        Invoke-NpmAuditFix
    #>
    [CmdletBinding()]
    param()

    try {
        Write-InfoLog -Scope "AUDIT-FIX" `
            -Message "Discovering directories for npm audit fix"

        $directories = Get-PackageLockDirectoriesWithPackageJson

        if ($null -eq $directories -or $directories.Count -eq 0) {
            Write-WarningLog -Scope "AUDIT-FIX" `
                -Message "No eligible directories found for audit fix"

            return
        }

        foreach ($directory in $directories) {
            Write-InfoLog -Scope "AUDIT-FIX" `
                -Message "Running npm audit fix --force with --prefix: $directory"

            & npm audit fix --force --prefix $directory

            if ($LASTEXITCODE -eq 0) {
                Write-InfoLog -Scope "AUDIT-FIX" `
                    -Message "Audit fix succeeded: $directory"
            } else {
                Write-WarningLog -Scope "AUDIT-FIX" `
                    -Message "Audit fix failed ($LASTEXITCODE): $directory"
            }
        }

    } catch {
        Write-WarningLog -Scope "AUDIT-FIX" `
            -Message "Error during npm audit fix: $($_.Exception.Message)"

        throw "Failed to run npm audit fix: $($_.Exception.Message)"
    }
}

#endregion

#region Primary Functions

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow for npm package setup automation.

    .DESCRIPTION
        Orchestrates the complete npm package setup process including
        prerequisites validation, PACKAGES file processing, and package
        installation with comprehensive error handling and progress feedback.
        Implements error continuation logic to process all packages even
        when individual packages fail, with comprehensive error logging
        and line-specific reporting for parsing errors.

    .EXAMPLE
        # Executes the complete npm package setup workflow.
        Invoke-PrimaryWorkflow
    #>
    [CmdletBinding()]
    param()

    try {
        # Validate prerequisites
        Assert-Prerequisites

        # Read and process PACKAGES file
        $packageLineList = Read-PackagesFile

        $packageCount = $packageLineList.Count

        if ($null -eq $packageLineList -or $packageLineList.Count -eq 0) {
            Write-WarningLog -Scope "PKG-PROCESS" `
                -Message "No packages found in PACKAGES file"

            throw "No packages found in PACKAGES file"
        } else {
            Write-InfoLog -Scope "PKG-PROCESS" `
                -Message "Found $packageCount package specifications"
        }

        # Iterate actual specification lines read from the PACKAGES file.
        foreach ($line in $packageLineList) {
            try{
                $packageData = ConvertFrom-PackageSpecification -Line $line

                if ($null -eq $packageData.Version) {
                    # Resolve version using package name property ("Name").
                    $packageData.Version = Get-LatestStableVersion `
                        -PackageName $packageData.Name
                }

                # Use $packageData.Name for package identifier.
                Install-NpmPackage `
                    -PackageName $packageData.Name `
                    -Version $packageData.Version `
                    -Flags $packageData.Flags

            } catch {
                # Intentionally continues on per-line failures to process
                # remaining packages.
                Write-ErrorLog -Scope "PKG-PROCESS" `
                    -Message ("Error processing package specification: " +
                        "'$Line' - $($_.Exception.Message)")
            }
        }

        Write-InfoLog -Scope "PKG-PROCESS" `
            -Message "Package installation phase completed"

        Invoke-NpmAuditFix

    } catch {
        throw "Primary workflow failed: $($_.Exception.Message)"
    }
}

#endregion

#region Main Script Execution

# Initialize environment
Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    Invoke-PrimaryWorkflow

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Completed successfully"

    exit 0

} catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Script execution failed: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
