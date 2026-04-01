# Core engine for build-go tool operations

import os, strutils, osproc
import utils

proc getCurrentPlatform*(): string =
    ## Get current platform name for executable output
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

proc formatSrc*(srcDir: string) =
    for path in walkDirRec(srcDir):
        if path.endsWith(".go"):
            let cmd = "gofmt -w \"" & path & "\""
            let (output, exitCode) = execCmdEx(cmd)
            if exitCode != 0:
                raise newException(OSError, "gofmt failed: " & output)

proc buildService*(serviceName: string): string =
    ## Build Go service executable for current platform
    ## Args: serviceName - Name of the service directory
    ## Returns: Absolute path to created executable
    let serviceDir = resolveServiceDir(serviceName)
    let fiberGoDir = absolutePath(serviceDir / "fiber-go")
    formatSrc(fiberGoDir)

    let platform = getCurrentPlatform()
    let distDir = absolutePath(fiberGoDir / "dist" / platform)
    let execBase = lastPathPart(serviceName)
    let execName = execBase & getExecutableExtension()
    let execPath = absolutePath(distDir / execName)

    # Create dist platform directory if needed
    if not dirExists(distDir):
        createDir(distDir)

    # Build the executable
    let buildCmd = "go build -ldflags \"-s -w\" -o \"" & execPath & "\" ."
    let (output, exitCode) = execCmdEx(buildCmd, workingDir = fiberGoDir)

    if exitCode != 0:
        raise newException(OSError, "Build failed: " & output)

    return execPath
