<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Executes repository setup commands from SETUP file with restrictions.

.DESCRIPTION
    This script processes the SETUP file and executes each line according
    to the rules defined in settings/setup.setting. It handles command
    expressions and executable file expressions, respecting platform
    restrictions, interpreter version requirements, command version
    requirements, and dependency validation. Each line is executed
    independently, and failures do not stop subsequent line execution.

    The script requires PSToml module for proper TOML parsing of the
    setup.setting configuration file.

    Restrictions enforced:
    - interpreter: Validates PowerShell interpreter for .ps1 files
    - interpreter_version: Validates PowerShell version matches requirement
    - command_version: Validates command version matches requirement
    - os_platform: Validates platform matches requirement
    - <platform>_dependency: Executes platform-specific dependencies

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.2.0
    Last Modified: 2026-02-08
    Platform: Windows only
    Requirements: pwsh 7.5.4, PSToml module

.EXAMPLE
    # Executes all setup commands from the SETUP file.
    .\scripts\setup-concise-repository.ps1

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Import required modules
$scriptPath = $PSScriptRoot
$conciseLogPath = Join-Path $scriptPath 'concise-log.psm1'
$coreModulePath = Join-Path $scriptPath 'powershell-core.psm1'

# Convert to absolute paths
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

Import-Module -Name $conciseLogPath -Force -ErrorAction Stop
Import-Module -Name $coreModulePath -Force -ErrorAction Stop

#region PSToml Module Functions

function Test-PSTomlInstalled {
    <#
    .SYNOPSIS
        Checks if PSToml module is installed.

    .DESCRIPTION
        Verifies if the PSToml module is available in the current
        PowerShell session by checking the list of available modules.

    .OUTPUTS
        System.Boolean. Returns $true if PSToml is installed.

    .EXAMPLE
        # Returns $true if PSToml module is installed.
        $isInstalled = Test-PSTomlInstalled
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $psTomlModule = Get-Module -Name 'PSToml' -ListAvailable `
        -ErrorAction SilentlyContinue

    if ($psTomlModule) {
        Write-DebugLog -Scope "MODULE-CHECK" `
            -Message "PSToml module is already installed"
        return $true
    }

    Write-DebugLog -Scope "MODULE-CHECK" `
        -Message "PSToml module is not installed"
    return $false
}

function Install-PSTomlModule {
    <#
    .SYNOPSIS
        Installs the PSToml module.

    .DESCRIPTION
        Installs the PSToml module from PowerShell Gallery using
        Install-Module cmdlet. The module is installed in the
        CurrentUser scope to avoid requiring administrator privileges.

    .OUTPUTS
        None. Throws an error if installation fails.

    .EXAMPLE
        # Installs the PSToml module for the current user.
        Install-PSTomlModule
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "MODULE-INSTALL" `
        -Message "Installing PSToml module from PowerShell Gallery"

    try {
        Install-Module -Name 'PSToml' -Scope CurrentUser `
            -Force -AllowClobber -ErrorAction Stop

        Write-InfoLog -Scope "MODULE-INSTALL" `
            -Message "PSToml module installed successfully"
    }
    catch {
        Write-ErrorLog -Scope "MODULE-INSTALL" `
            -Message "Failed to install PSToml: $($_.Exception.Message)"

        throw "PSToml module installation failed"
    }
}

function Initialize-PSTomlModule {
    <#
    .SYNOPSIS
        Ensures PSToml module is installed and imported.

    .DESCRIPTION
        Checks if PSToml module is installed, installs it if not found,
        and imports it into the current session. This function ensures
        the module is ready for use.

    .OUTPUTS
        None. Throws an error if module cannot be initialized.

    .EXAMPLE
        # Ensures PSToml module is installed and imported.
        Initialize-PSTomlModule
    #>
    [CmdletBinding()]
    param()

    $isInstalled = Test-PSTomlInstalled

    if (-not $isInstalled) {
        Write-InfoLog -Scope "MODULE-INIT" `
            -Message "PSToml module not found, installing"

        Install-PSTomlModule

        $isInstalled = Test-PSTomlInstalled

        if (-not $isInstalled) {
            throw "PSToml module installation verification failed"
        }
    }

    try {
        Import-Module -Name 'PSToml' -Force -ErrorAction Stop

        Write-InfoLog -Scope "MODULE-INIT" `
            -Message "PSToml module imported successfully"
    }
    catch {
        Write-ErrorLog -Scope "MODULE-INIT" `
            -Message "Failed to import PSToml: $($_.Exception.Message)"

        throw "PSToml module import failed"
    }
}

#endregion

#region Version Functions

function Get-CommandVersion {
    <#
    .SYNOPSIS
        Gets the version of an installed command.

    .DESCRIPTION
        Retrieves the version of a command by executing it with the
        --version flag. Returns the first line of output trimmed.
        Future support for other version flags can be added here.

    .PARAMETER CommandName
        The name of the command to check.

    .OUTPUTS
        System.String. The version string or empty if not found.

    .EXAMPLE
        # Returns the node version string (e.g., "v24.13.0")
        $version = Get-CommandVersion -CommandName 'node'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName
    )

    $command = Get-Command -Name $CommandName `
        -ErrorAction SilentlyContinue

    if (-not $command) {
        return ""
    }

    try {
        $output = & $CommandName --version 2>&1 | Select-Object -First 1

        if ($output) {
            return $output.ToString().Trim()
        }
    }
    catch {
        Write-DebugLog -Scope "VERSION-GET" `
            -Message "Failed to get version for $CommandName"
    }

    return ""
}

function Test-CommandVersionMatch {
    <#
    .SYNOPSIS
        Tests if command version matches required version exactly.

    .DESCRIPTION
        Checks if the installed command version matches the required
        version specification using strict exact match comparison.
        No normalization or manipulation is performed.

    .PARAMETER CommandName
        The name of the command to check.

    .PARAMETER RequiredVersion
        The required version specification for exact match.

    .OUTPUTS
        System.Boolean. Returns $true if version matches exactly.

    .EXAMPLE
        # Returns $true if node version matches exactly.
        $matches = Test-CommandVersionMatch -CommandName 'node' `
            -RequiredVersion 'v24.13.0'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RequiredVersion
    )

    $currentVersion = Get-CommandVersion -CommandName $CommandName

    if ([string]::IsNullOrWhiteSpace($currentVersion)) {
        Write-DebugLog -Scope "VERSION-CHECK" `
            -Message "Could not determine version for $CommandName"

        return $false
    }

    $isMatch = $currentVersion -eq $RequiredVersion

    if (-not $isMatch) {
        $mismatchMessage = "$CommandName version mismatch: " + `
            "$currentVersion != $RequiredVersion"

        Write-DebugLog -Scope "VERSION-CHECK" -Message $mismatchMessage
    }

    return $isMatch
}

function Get-InterpreterVersion {
    <#
    .SYNOPSIS
        Gets the version of the PowerShell interpreter.

    .DESCRIPTION
        Retrieves the PowerShell interpreter version by executing
        pwsh with the --version flag. Returns the first line of
        output trimmed. Future support for other interpreters can
        be added here.

    .OUTPUTS
        System.String. The interpreter version string.

    .EXAMPLE
        # Returns "PowerShell 7.5.4"
        $version = Get-InterpreterVersion
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        $output = & pwsh --version 2>&1 | Select-Object -First 1

        if ($output) {
            return $output.ToString().Trim()
        }
    }
    catch {
        Write-DebugLog -Scope "VERSION-GET" `
            -Message "Failed to get interpreter version"
    }

    return ""
}

function Test-InterpreterVersionMatch {
    <#
    .SYNOPSIS
        Tests if interpreter version matches required version exactly.

    .DESCRIPTION
        Checks if the PowerShell interpreter version matches the
        required version specification using strict exact match
        comparison. No normalization or manipulation is performed.

    .PARAMETER RequiredVersion
        The required interpreter version for exact match.

    .OUTPUTS
        System.Boolean. Returns $true if version matches exactly.

    .EXAMPLE
        # Returns $true if interpreter version matches exactly.
        $matches = Test-InterpreterVersionMatch `
            -RequiredVersion 'PowerShell 7.5.4'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RequiredVersion
    )

    $currentVersion = Get-InterpreterVersion

    if ([string]::IsNullOrWhiteSpace($currentVersion)) {
        Write-DebugLog -Scope "VERSION-CHECK" `
            -Message "Could not determine interpreter version"

        return $false
    }

    $isMatch = $currentVersion -eq $RequiredVersion

    if (-not $isMatch) {
        $mismatchMessage = "Interpreter version mismatch: " + `
            "$currentVersion != $RequiredVersion"

        Write-DebugLog -Scope "VERSION-CHECK" -Message $mismatchMessage
    }

    return $isMatch
}

#endregion

#region Configuration Functions

function Get-RepositoryRoot {
    <#
    .SYNOPSIS
        Gets the repository root directory path.

    .DESCRIPTION
        Determines the repository root directory by checking for git
        repository or using the parent directory of the scripts folder.

    .OUTPUTS
        System.String. The repository root directory path.

    .EXAMPLE
        # Returns the repository root directory path.
        $repositoryRoot = Get-RepositoryRoot
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $repositoryRoot = Split-Path -Parent $PSScriptRoot

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($gitCommand) {
        try {
            $detectedRoot = (& git rev-parse --show-toplevel 2>$null)
            if ($detectedRoot -and (Test-Path -LiteralPath $detectedRoot)) {
                $repositoryRoot = $detectedRoot
            }
        } catch {
            Write-DebugLog -Scope "REPO-ROOT" `
                -Message "Git root detection failed, using parent directory"
        }
    }

    return $repositoryRoot
}

function Test-RequiredFilesExist {
    <#
    .SYNOPSIS
        Validates that required files exist.

    .DESCRIPTION
        Checks if the SETUP file and settings/setup.setting file exist
        in the repository root. Throws an error if either file is missing.

    .PARAMETER RepositoryRoot
        The repository root directory path.

    .OUTPUTS
        None. Throws an error if required files are missing.

    .EXAMPLE
        # Validates that required files exist.
        Test-RequiredFilesExist -RepositoryRoot $repositoryRoot
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )

    $setupFilePath = Join-Path $RepositoryRoot 'SETUP'
    $settingFilePath = Join-Path $RepositoryRoot 'settings\setup.setting'

    # Convert to absolute paths
    $setupFilePath = [System.IO.Path]::GetFullPath($setupFilePath)
    $settingFilePath = [System.IO.Path]::GetFullPath($settingFilePath)

    if (-not (Test-Path -LiteralPath $setupFilePath)) {
        throw "Required file not found: $setupFilePath"
    }

    if (-not (Test-Path -LiteralPath $settingFilePath)) {
        throw "Required file not found: $settingFilePath"
    }

    Write-InfoLog -Scope "FILE-CHECK" `
        -Message "Required files validated successfully"
}

#endregion

#region Setting Parser Functions

function Read-SetupSetting {
    <#
    .SYNOPSIS
        Reads and parses the setup.setting file.

    .DESCRIPTION
        Parses the setup.setting file using PSToml module to extract
        platform mappings, file platform restrictions, and dependency
        requirements.

    .PARAMETER SettingFilePath
        The path to the setup.setting file.

    .OUTPUTS
        System.Collections.Hashtable. Contains platform mappings,
        file restrictions, and dependencies.

    .EXAMPLE
        # Returns parsed settings from setup.setting file.
        $settings = Read-SetupSetting -SettingFilePath $settingFilePath
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SettingFilePath
    )

    $settings = @{
        OSPlatformMap = @{}
        FileRestrictions = @{}
        Dependencies = @{}
        CommandRestrictions = @{}
    }

    $content = Get-Content -LiteralPath $SettingFilePath -Raw
    $tomlData = ConvertFrom-Toml -InputObject $content

    if ($tomlData.Contains('os_platform') `
        -and $tomlData['os_platform'].Contains('map')) {
        $settings.OSPlatformMap = $tomlData['os_platform']['map']
    }

    foreach ($key in $tomlData.Keys) {
        if ($key -match '^\*\.(.+)$') {
            $extension = $key
            $fileConfig = $tomlData[$key]

            if ($fileConfig.Contains('os_platform')) {
                $settings.FileRestrictions[$extension] = @{
                    OSPlatform = $fileConfig['os_platform']
                    Interpreter = $fileConfig['interpreter']
                    InterpreterVersion = $fileConfig['interpreter_version']
                }
            }
        }
        elseif ($key -notin @('os_platform')) {
            $commandConfig = $tomlData[$key]

            $settings.CommandRestrictions[$key] = @{
                CommandVersion = $commandConfig['command_version']
                OSPlatform = $commandConfig['os_platform']
            }

            $dependencyKeys = $commandConfig.Keys | `
                Where-Object { $_ -match '_dependency$' }

            if ($dependencyKeys) {
                if (-not $settings.Dependencies.Contains($key)) {
                    $settings.Dependencies[$key] = @{}
                }

                foreach ($dependencyKey in $dependencyKeys) {
                    $settings.Dependencies[$key][$dependencyKey] = `
                        $commandConfig[$dependencyKey]
                }
            }
        }
    }

    Write-InfoLog -Scope "TOML-PARSE" `
        -Message "Successfully parsed TOML using PSToml module"

    return $settings
}

function Get-CurrentPlatform {
    <#
    .SYNOPSIS
        Gets the current platform identifier.

    .DESCRIPTION
        Determines the current os platform using environment
        variables and maps it to a standardized platform name.
        Throws an error if the platform is not found in the mapping.

    .PARAMETER Settings
        The parsed settings from setup.setting file.

    .OUTPUTS
        System.String. The current os platform identifier.

    .EXAMPLE
        # Returns the current os platform identifier.
        $osPlatform = Get-CurrentPlatform -Settings $settings
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    $osPlatformKey = $env:OS
    if ([string]::IsNullOrWhiteSpace($osPlatformKey)) {
        $osPlatformKey = $PSVersionTable.Platform
    }

    if ($Settings.OSPlatformMap.Contains($osPlatformKey)) {
        return $Settings.OSPlatformMap[$osPlatformKey]
    }

    throw "OS platform '$osPlatformKey' not found in os_platform.map"
}

#endregion

#region Execution Functions

function Test-CanExecuteFile {
    <#
    .SYNOPSIS
        Tests if a file can be executed on the current os
        platform.

    .DESCRIPTION
        Checks if a file has os platform and interpreter
        version restrictions and validates if it can be executed on the
        current os platform based on the settings.

    .PARAMETER FilePath
        The path to the file to check.

    .PARAMETER Settings
        The parsed settings from setup.setting file.

    .PARAMETER CurrentOSPlatform
        The current os platform identifier.

    .OUTPUTS
        System.Boolean. Returns $true if file can be executed.

    .EXAMPLE
        # Returns $true if file can be executed on current platform.
        $canExecute = Test-CanExecuteFile -FilePath $filePath `
            -Settings $settings `
            -CurrentOSPlatform $osPlatform
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CurrentOSPlatform
    )

    $extension = [System.IO.Path]::GetExtension($FilePath)

    if (-not $Settings.FileRestrictions.Contains($extension)) {
        return $true
    }

    $restrictions = $Settings.FileRestrictions[$extension]

    if ($restrictions -is [string]) {
        return $CurrentOSPlatform -eq $restrictions
    }

    if ($restrictions.Contains('OSPlatform')) {
        $requiredOSPlatform = $restrictions['OSPlatform']

        # Skip if os_platform is false (no platform restriction)
        if ($requiredOSPlatform -is [bool] -and -not $requiredOSPlatform) {
            # No os platform restriction, continue to next check
        }
        else{
            if ($CurrentOSPlatform -ne $requiredOSPlatform) {
                $platformMessage = "OS platform mismatch: need $requiredOSPlatform"

                Write-WarningLog -Scope "FILE-RESTRICT" -Message $platformMessage

                return $false
            }
        }
    }

    if ($restrictions.Contains('InterpreterVersion')) {
        $requiredVersion = $restrictions['InterpreterVersion']

        # Skip if version is false (no version restriction)
        if ($requiredVersion -is [bool] -and -not $requiredVersion) {
            # No version restriction, continue
        }
        else {
            $isVersionMatch = Test-InterpreterVersionMatch `
                -RequiredVersion $requiredVersion

            if (-not $isVersionMatch) {
                Write-WarningLog -Scope "FILE-RESTRICT" `
                    -Message "Interpreter version mismatch: need $requiredVersion"

                return $false
            }
        }
    }

    return $true
}

function Test-CanExecuteCommand {
    <#
    .SYNOPSIS
        Tests if a command can be executed with current restrictions.

    .DESCRIPTION
        Checks if a command has os platform and version
        restrictions and validates if it can be executed based on the
        settings.

    .PARAMETER CommandName
        The name of the command to check.

    .PARAMETER Settings
        The parsed settings from setup.setting file.

    .PARAMETER CurrentOSPlatform
        The current os platform identifier.

    .OUTPUTS
        System.Boolean. Returns $true if command can be executed.

    .EXAMPLE
        # Returns $true if command can be executed on current platform.
        $canExecute = Test-CanExecuteCommand `
            -CommandName 'node' `
            -Settings $settings `
            -CurrentOSPlatform 'windows'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CurrentOSPlatform
    )

    if (-not $Settings.CommandRestrictions.Contains($CommandName)) {
        return $true
    }

    $restrictions = $Settings.CommandRestrictions[$CommandName]

    if ($restrictions.Contains('OSPlatform')) {
        $requiredOSPlatform = $restrictions['OSPlatform']

        # Skip if os_platform is false (no platform restriction)
        if ($requiredOSPlatform -is [bool] -and -not $requiredOSPlatform) {
            # No os platform restriction, continue to next check
        }
        else{
            if ($CurrentOSPlatform -ne $requiredOSPlatform) {
                $platformMessage = "$CommandName OS platform mismatch: " + `
                    "need $requiredOSPlatform"

                Write-WarningLog -Scope "CMD-RESTRICT" -Message $platformMessage

                return $false
            }
        }
    }

    if ($restrictions.Contains('CommandVersion')) {
        $requiredVersion = $restrictions['CommandVersion']

        # Skip if version is false (no version restriction)
        if ($requiredVersion -is [bool] -and -not $requiredVersion) {
            # No version restriction, continue
        }
        else{
            $isVersionMatch = Test-CommandVersionMatch `
                -CommandName $CommandName `
                -RequiredVersion $requiredVersion

            if (-not $isVersionMatch) {
                Write-WarningLog -Scope "CMD-RESTRICT" `
                    -Message "$CommandName version mismatch: need $requiredVersion"

                return $false
            }
        }
    }

    return $true
}

function Invoke-DependencyExecution {
    <#
    .SYNOPSIS
        Executes dependency script before main command.

    .DESCRIPTION
        Checks if a command has dependencies and executes the
        dependency script for the current os platform
        before proceeding.

    .PARAMETER CommandName
        The command name to check for dependencies.

    .PARAMETER Settings
        The parsed settings from setup.setting file.

    .PARAMETER CurrentOSPlatform
        The current os platform identifier.

    .PARAMETER RepositoryRoot
        The repository root directory path.

    .OUTPUTS
        System.Boolean. Returns $true if dependency executed successfully.

    .EXAMPLE
        # Executes dependency script if required.
        $success = Invoke-DependencyExecution `
            -CommandName 'npx' `
            -Settings $settings `
            -CurrentOSPlatform $osPlatform `
            -RepositoryRoot $repositoryRoot
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CurrentOSPlatform,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )

    if (-not $Settings.Dependencies.Contains($CommandName)) {
        return $true
    }

    $dependencyKey = "${CurrentOSPlatform}_dependency"
    $dependencies = $Settings.Dependencies[$CommandName]

    if (-not $dependencies.Contains($dependencyKey)) {
        return $true
    }

    $dependencyScript = $dependencies[$dependencyKey]

    # Skip if dependency is false (no dependency required)
    if ($dependencyScript -is [bool] -and -not $dependencyScript) {
        return $true
    }

    $dependencyPath = Join-Path $RepositoryRoot $dependencyScript
    $dependencyPath = [System.IO.Path]::GetFullPath($dependencyPath)

    # Check if dependency has already been executed successfully
    $dependencyCacheKey = "${dependencyPath}"
    if ($script:executedDependencies.ContainsKey($dependencyCacheKey)) {
        Write-InfoLog -Scope "DEPENDENCY-EXEC" `
            -Message "Dependency already executed: $dependencyScript"

        return $true
    }

    if (-not (Test-Path -LiteralPath $dependencyPath)) {
        Write-WarningLog -Scope "DEPENDENCY-EXEC" `
            -Message "Dependency script not found: $dependencyScript"

        return $false
    }

    Write-InfoLog -Scope "DEPENDENCY-EXEC" `
        -Message "Executing dependency: $dependencyScript"

    try {
        & pwsh -NoProfile -ExecutionPolicy Bypass `
            -File $dependencyPath

        if ($LASTEXITCODE -ne 0) {
            Write-WarningLog -Scope "DEPENDENCY-EXEC" `
                -Message "Dependency script failed with code $LASTEXITCODE"

            return $false
        }

        Write-InfoLog -Scope "DEPENDENCY-EXEC" `
            -Message "Dependency executed successfully"

        # Add to cache to prevent redundant executions
        $script:executedDependencies[$dependencyCacheKey] = $true

        return $true
    }
    catch {
        Write-ErrorLog -Scope "DEPENDENCY-EXEC" `
            -Message "Dependency execution failed: $($_.Exception.Message)"

        return $false
    }
}

function Invoke-SetupLine {
    <#
    .SYNOPSIS
        Executes a single line from the SETUP file.

    .DESCRIPTION
        Parses and executes a single line from the SETUP file. Handles
        command expressions and executable file expressions. Respects
        os platform restrictions and executes dependencies
        if required.

    .PARAMETER Line
        The line to execute from the SETUP file.

    .PARAMETER LineNumber
        The line number for logging purposes.

    .PARAMETER Settings
        The parsed settings from setup.setting file.

    .PARAMETER CurrentOSPlatform
        The current os platform identifier.

    .PARAMETER RepositoryRoot
        The repository root directory path.

    .OUTPUTS
        None. Logs execution results.

    .EXAMPLE
        # Executes a single line from the SETUP file.
        Invoke-SetupLine `
            -Line $line `
            -LineNumber $lineNumber `
            -Settings $settings `
            -CurrentOSPlatform $osPlatform `
            -RepositoryRoot $repositoryRoot
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line,

        [Parameter(Mandatory = $true)]
        [int]$LineNumber,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CurrentOSPlatform,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )

    $trimmedLine = $Line.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
        Write-DebugLog -Scope "SETUP-EXEC" `
            -Message "Line $LineNumber is empty, skipping"

        return
    }

    if ($trimmedLine.StartsWith('#')) {
        Write-DebugLog -Scope "SETUP-EXEC" `
            -Message "Line $LineNumber is a comment, skipping"

        return
    }

    Write-InfoLog -Scope "SETUP-EXEC" `
        -Message "Executing line $LineNumber : $trimmedLine"

    $tokens = $trimmedLine -split '\s+'
    $firstToken = $tokens[0]

    $isExecutableFile = $firstToken -match '\.(ps1|sh|bash)$'

    if ($isExecutableFile) {
        $filePath = Join-Path $RepositoryRoot $firstToken

        if (-not (Test-Path -LiteralPath $filePath)) {
            Write-ErrorLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : File not found: $firstToken"

            return
        }

        $canExecute = Test-CanExecuteFile `
            -FilePath $filePath `
            -Settings $Settings `
            -CurrentOSPlatform $CurrentOSPlatform

        if (-not $canExecute) {
            Write-WarningLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : File cannot execute on OS platform"

            return
        }

        try {
            # Extract arguments from the original line
            # (everything after the first token)
            $arguments = $trimmedLine.Substring($firstToken.Length).Trim()

            if (-not [string]::IsNullOrWhiteSpace($arguments)) {
                Write-DebugLog -Scope "SETUP-EXEC" `
                    -Message ("Line $LineNumber : " +
                        "Executing with arguments: $arguments")

                # Split arguments properly and pass them as separate parameters
                $argumentList = $arguments -split '\s+' |
                    Where-Object { $_ -ne '' }

                & pwsh -NoProfile -ExecutionPolicy Bypass `
                    -File $filePath @argumentList
            }
            else {
                & pwsh -NoProfile -ExecutionPolicy Bypass -File $filePath
            }

            if ($LASTEXITCODE -eq 0) {
                Write-InfoLog -Scope "SETUP-EXEC" `
                    -Message "Line $LineNumber : Executed successfully"
            }
            else {
                Write-ErrorLog -Scope "SETUP-EXEC" `
                    -Message "Line $LineNumber : Failed with code $LASTEXITCODE"
            }
        }
        catch {
            Write-ErrorLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : Exception: $($_.Exception.Message)"
        }
    }
    else {
        $commandName = $firstToken

        $canExecute = Test-CanExecuteCommand `
            -CommandName $commandName `
            -Settings $Settings `
            -CurrentOSPlatform $CurrentOSPlatform

        if (-not $canExecute) {
            Write-WarningLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : Command restrictions not met"

            return
        }

        $dependencySuccess = Invoke-DependencyExecution `
            -CommandName $commandName `
            -Settings $Settings `
            -CurrentOSPlatform $CurrentOSPlatform `
            -RepositoryRoot $RepositoryRoot

        if (-not $dependencySuccess) {
            Write-WarningLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : Dependency failed, continuing"
        }

        try {
            Invoke-Expression $trimmedLine

            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                Write-InfoLog -Scope "SETUP-EXEC" `
                    -Message "Line $LineNumber : Executed successfully"
            }
            else {
                Write-ErrorLog -Scope "SETUP-EXEC" `
                    -Message "Line $LineNumber : Failed with code $LASTEXITCODE"
            }
        }
        catch {
            Write-ErrorLog -Scope "SETUP-EXEC" `
                -Message "Line $LineNumber : Exception: $($_.Exception.Message)"
        }
    }
}

#endregion

#region Primary Functions

function Invoke-SetupExecution {
    <#
    .SYNOPSIS
        Executes all lines from the SETUP file.

    .DESCRIPTION
        Reads the SETUP file and executes each line according to the
        rules defined in settings/setup.setting. Each line is executed
        independently, and failures do not stop subsequent execution.

    .OUTPUTS
        None. Logs execution results for each line.

    .EXAMPLE
        # Executes all lines from the SETUP file.
        Invoke-SetupExecution
    #>
    [CmdletBinding()]
    param()

    $repositoryRoot = Get-RepositoryRoot

    Write-InfoLog -Scope "SETUP-INIT" `
        -Message "Repository root: $repositoryRoot"

    Test-RequiredFilesExist -RepositoryRoot $repositoryRoot

    $setupFilePath = Join-Path $repositoryRoot 'SETUP'
    $settingFilePath = Join-Path $repositoryRoot 'settings\setup.setting'

    $setupFilePath = [System.IO.Path]::GetFullPath($setupFilePath)
    $settingFilePath = [System.IO.Path]::GetFullPath($settingFilePath)

    $settings = Read-SetupSetting -SettingFilePath $settingFilePath
    $currentOSPlatform = Get-CurrentPlatform -Settings $settings

    Write-InfoLog -Scope "SETUP-INIT" `
        -Message "Current OS platform: $currentOSPlatform"

    $setupContent = Get-Content -LiteralPath $setupFilePath
    $lineNumber = 0

    foreach ($line in $setupContent) {
        $lineNumber++

        Invoke-SetupLine `
            -Line $line `
            -LineNumber $lineNumber `
            -Settings $settings `
            -CurrentOSPlatform $currentOSPlatform `
            -RepositoryRoot $repositoryRoot
    }

    Write-InfoLog -Scope "SETUP-COMPLETE" `
        -Message "Setup execution completed"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

# Initialize PSToml module (install if needed)
Initialize-PSTomlModule

# Track executed dependencies to avoid redundant executions
$script:executedDependencies = @{}

try {
    Invoke-SetupExecution

    exit 0
}
catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Failed to setup repository: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
