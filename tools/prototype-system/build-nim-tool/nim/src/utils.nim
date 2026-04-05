
import os, osproc, strutils
import settings

proc getCurrentPlatform*(): string =

    ## Get current platform name for executable output
    ## Returns: Platform name (windows, linux, darwin)

    when defined(windows):
        return "windows"
    elif defined(linux):
        return "linux"
    elif defined(macosx):
        return "darwin"
    else:
        raise newException(OSError, "unsupported platform")

proc getRepositoryRootDirectory*(): string =

    ## Find repository root directory using git repository detection
    ## Returns: Absolute path to repository root directory (git repository root)

    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        let repositoryRootPath = output.strip()
        if repositoryRootPath != "" and dirExists(repositoryRootPath):
            return absolutePath(repositoryRootPath)

        raise newException(OSError,
            "repository root directory not found, " & repositoryRootPath)

    raise newException(OSError,
        "cannot determine repository root directory path")

proc getToolsRootDirectory*(): string =

    ## Get absolute path to tools directory
    ## Returns: Absolute path to tools directory

    let toolsRootDirectory = getRepositoryRootDirectory() / toolsDirectory

    if dirExists(toolsRootDirectory):
        return toolsRootDirectory

    raise newException(OSError,
        "tools root directory not found, " & toolsRootDirectory)

proc resolveToolSourceDirectory*(tool: string): string =

    ## Resolve tool source directory by relative path 'name-system/name-tool'
    ## Args: tool - Relative tool path under tools directory
    ## Returns: Absolute path to tool source directory

    let toolSourcePath = (
        getToolsRootDirectory() / normalizedPath(tool) / sourceDirectory
    )

    if dirExists(toolSourcePath):
        return toolSourcePath

    raise newException(OSError,
        "tool source directory not found, " & toolSourcePath)

proc resolveToolMainFile*(tool: string): string =

    let toolSourceDirectory = resolveToolSourceDirectory(tool)

    return toolSourceDirectory / mainFile

proc resolveToolTargetBuildDirectory*(tool: string): string =

    ## Resolve tool target build directory by relative path 'name-system/name-tool'
    ## Args: tool - Relative tool path under tools directory
    ## Returns: Absolute path to tool target build directory

    let toolTargetBuildPath = (
        getToolsRootDirectory() / normalizedPath(tool) / targetBuildDirectory
    )

    if dirExists(toolTargetBuildPath):
        return toolTargetBuildPath

    raise newException(OSError,
        "tool target build directory not found, " & toolTargetBuildPath)

proc resolveExecutableExtension*(): string =

    ## Resolve executable file extension for current platform
    ## Returns: File extension (.exe for Windows, empty for others)

    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableToolFile*(tool: string): string =

    let toolTargetBuildDirectory = resolveToolTargetBuildDirectory(tool)
    let buildDirectory = toolTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(tool) & resolveExecutableExtension()

    return buildDirectory / executableFile
