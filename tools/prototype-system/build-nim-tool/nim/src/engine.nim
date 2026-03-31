# Core engine for build-nim tool operations

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
        if path.endsWith(".nim"):
            let cmd = "nimpretty --indent:4 \"" & path & "\""
            let (output, exitCode) = execCmdEx(cmd)
            if exitCode != 0:
                raise newException(OSError, "nimpretty failed: " & output)

proc buildTool*(toolName: string): string =
    ## Build Nim tool executable for current platform
    ## Args: toolName - Name of the tool directory
    ## Returns: Absolute path to created executable
    let toolDir = resolveToolDir(toolName)
    let nimDir = absolutePath(toolDir / "nim")
    let srcDir = absolutePath(nimDir / "src")
    let mainFile = absolutePath(srcDir / "main.nim")
    formatSrc(srcDir)

    let platform = getCurrentPlatform()
    let distDir = absolutePath(nimDir / "dist" / platform)
    let execBase = lastPathPart(toolName)
    let execName = execBase & getExecutableExtension()
    let execPath = absolutePath(distDir / execName)

    # Create dist platform directory if needed
    if not dirExists(distDir):
        createDir(distDir)

    # Build the executable
    let buildCmd = "nim compile -d:release --out:" & execPath & " " & mainFile
    let (output, exitCode) = execCmdEx(buildCmd)

    if exitCode != 0:
        raise newException(OSError, "Build failed: " & output)

    return execPath
