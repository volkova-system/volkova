# Core engine for build-zig tool operations

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
        if path.endsWith(".zig"):
            let cmd = "zig fmt \"" & path & "\""
            let (output, exitCode) = execCmdEx(cmd)
            if exitCode != 0:
                raise newException(OSError, "zig fmt failed: " & output)

proc buildCli*(cliName: string): string =
    ## Build Zig CLI executable for current platform
    ## Args: cliName - Name of the CLI directory
    ## Returns: Absolute path to created executable
    let cliDir = resolveCliDir(cliName)
    let zigDir = absolutePath(cliDir / "zig")
    let srcDir = absolutePath(zigDir / "src")
    let mainFile = absolutePath(srcDir / "main.zig")
    formatSrc(srcDir)

    let platform = getCurrentPlatform()
    let distDir = absolutePath(zigDir / "dist" / platform)
    let execBase = lastPathPart(cliName)
    let execName = execBase & getExecutableExtension()
    let execPath = absolutePath(distDir / execName)

    # Create dist platform directory if needed
    if not dirExists(distDir):
        createDir(distDir)

    # Build the executable
    let buildCmd = "zig build-exe -O ReleaseFast -femit-bin=" & execPath & " " & mainFile
    let (output, exitCode) = execCmdEx(buildCmd)

    if exitCode != 0:
        raise newException(OSError, "Build failed: " & output)

    return execPath
