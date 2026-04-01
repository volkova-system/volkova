# Core engine for install-zig tool operations

import os, osproc, strutils
import utils

proc getCurrentPlatform*(): string =
    ## Get current platform name matching build-zig output directory
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

proc resolveExecutablePath*(cliName: string): string =
    ## Resolve the expected executable path within the CLI directory
    ## Args: cliName - Relative CLI path 'name-system/name-cli'
    ## Returns: Absolute path to the expected executable file
    let cliDir = utils.resolveCliDir(cliName)
    let cliNameOnly = lastPathPart(cliName)
    let platform = getCurrentPlatform()
    let execName = cliNameOnly & getExecutableExtension()
    let execPath = absolutePath(
        cliDir / "zig" / "dist" / platform / execName
    )
    return execPath

proc getInstallDirectory*(): string =
    ## Get the system-wide install directory for the current platform
    ## Returns: Absolute path to the install directory
    when defined(windows):
        return absolutePath(getEnv("ProgramFiles") / "zig-tools" / "bin")
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

proc ensureInstallDirOnPath*(installDir: string): bool =
    when defined(windows):
        let dir = absolutePath(installDir)
        let quotedDir = dir.replace("\\", "\\\\")
        let ps1 = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " &
                  "\"$p=[Environment]::GetEnvironmentVariable('Path','Machine');" &
                  "$i='" & quotedDir & "';" &
                  "if ($p -split ';' -notcontains $i) {[Environment]::SetEnvironmentVariable('Path',$i+';'+$p,'Machine');}\""
        let (_, code1) = execCmdEx(ps1)
        if code1 == 0:
            putEnv("PATH", dir & ";" & getEnv("PATH"))
            return true
        let ps2 = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " &
                  "\"$p=[Environment]::GetEnvironmentVariable('Path','User');" &
                  "$i='" & quotedDir & "';" &
                  "if ($p -split ';' -notcontains $i) {[Environment]::SetEnvironmentVariable('Path',$i+';'+$p,'User');}\""
        let (_, code2) = execCmdEx(ps2)
        if code2 == 0:
            putEnv("PATH", dir & ";" & getEnv("PATH"))
            return true
        return false
    else:
        return false
