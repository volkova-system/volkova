
import os, osproc, strutils
import settings

proc getCurrentPlatform*(): string =
    when defined(windows):
        return "windows"

    elif defined(linux):
        return "linux"

    elif defined(macosx):
        return "darwin"

    else:
        raise newException(OSError, "unsupported platform")

proc getRepositoryRootDirectory*(): string =
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        return output.strip()

    raise newException(OSError, "cannot determine repository root directory path")

proc getInstallDirectory*(): string =
    if not dirExists(installDirectory):
        createDir(installDirectory)

    return installDirectory

proc resolveSystemsRootDirectory*(): string =
    return getRepositoryRootDirectory() / toolsDirectory

proc resolveToolTargetBuildDirectory*(tool: string): string =
    return resolveToolsRootDirectory() / normalizedPath(tool) / targetBuildDirectory

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableToolFile*(tool: string): string =
    let toolTargetBuildDirectory = resolveToolTargetBuildDirectory(tool)
    let buildDirectory = toolTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(tool) & resolveExecutableExtension()

    return buildDirectory / executableFile



