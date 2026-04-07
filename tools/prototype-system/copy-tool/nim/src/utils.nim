
import os, strutils, osproc
import settings

proc getCurrentPlatform*(): string =
    when defined(windows):
        return "windows"

    elif defined(linux):
        return "linux"

    elif defined(macosx):
        return "darwin"

    else:
        raise newException(OSError,
            "unsupported platform")

proc getRepositoryRootDirectory*(): string =
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        return output.strip()

    raise newException(OSError,
        "cannot determine repository root directory path")

proc resolveToolsRootDirectory*(): string =
    return getRepositoryRootDirectory() / toolsDirectory

proc resolveSystemsRootDirectory*(): string =
    return getRepositoryRootDirectory() / systemsDirectory

proc resolveSourceToolDirectory*(source: string): string =
    return resolveToolsRootDirectory() / normalizedPath(source) / toolLanguage / toolBuildDirectory / getCurrentPlatform()

proc resolveTargetToolsDirectory*(target: string): string =
    return resolveSystemsRootDirectory() / normalizedPath(target) / getCurrentPlatform()

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveSourceToolExecutable*(source: string): string =
    return resolveSourceToolDirectory(source) / lastPathPart(source) & resolveExecutableExtension()

proc resolveTargetToolExecutable*(target: string, source: string): string =
    return resolveTargetToolsDirectory(target) / lastPathPart(source) & resolveExecutableExtension()

