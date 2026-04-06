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

proc resolveSourceToolDirectory*(toolPath: string): string =
    return resolveToolsRootDirectory() / normalizedPath(toolPath)

proc resolveTargetToolsDirectory*(toolsPath: string): string =
    return resolveToolsRootDirectory() / normalizedPath(toolsPath)
