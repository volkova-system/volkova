# Core engine for install-nim tool operations

import os
import utils

proc getCurrentPlatform*(): string =
    ## Get current platform name matching build-nim output directory
    ## Returns: Platform name (windows, linux, macos)
    when defined(windows):
        return "windows"
    elif defined(linux):
        return "linux"
    elif defined(macosx):
        return "darwin"
    else:
        raise newException(OSError, "unsupported platform")

proc getExecutableExtension*(): string =
    ## Get executable file extension for current platform
    ## Returns: File extension (.exe for Windows, empty for others)
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutablePath*(toolName: string): string =
    ## Resolve the expected executable path within the tool directory
    ## Args: toolName - Relative tool path 'name-system/name-tool'
    ## Returns: Absolute path to the expected executable file
    let toolDir = utils.resolveToolDir(toolName)
    let toolNameOnly = lastPathPart(toolName)
    let platform = getCurrentPlatform()
    let execName = toolNameOnly & getExecutableExtension()
    let execPath = absolutePath(
        toolDir / "nim" / "dist" / platform / execName
    )
    return execPath

proc getInstallDirectory*(): string =
    ## Get the system-wide install directory for the current platform
    ## Returns: Absolute path to the install directory
    when defined(windows):
        return absolutePath(getEnv("ProgramFiles") / "nim-tools" / "bin")
    elif defined(linux):
        return "/usr/local/bin"
    elif defined(macosx):
        return "/usr/local/bin"

proc installExecutable*(execPath: string, installDir: string): string =
    ## Install the executable to the system-wide install directory
    ## Args: execPath - Absolute path to the source executable
    ##       installDir - Absolute path to the install directory
    ## Returns: Absolute path to the installed executable
    let execName = lastPathPart(execPath)
    let destPath = absolutePath(installDir / execName)

    # Create install directory if it does not exist
    if not dirExists(installDir):
        createDir(installDir)

    # Copy executable to install directory
    copyFile(execPath, destPath)

    when defined(linux) or defined(macosx):
        # Set executable permissions for all users
        setFilePermissions(
            destPath,
            {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
             fpOthersExec, fpOthersRead}
        )

    return destPath
