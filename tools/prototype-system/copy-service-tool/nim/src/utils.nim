
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

proc resolveServicesRootDirectory*(): string =
    return getRepositoryRootDirectory() / servicesDirectory

proc resolveSystemsRootDirectory*(): string =
    return getRepositoryRootDirectory() / systemsDirectory

proc resolveServiceDirectory*(target: string): string =
    return resolveServicesRootDirectory() / normalizedPath(target)

proc resolveSystemDirectory*(target: string): string =
    return resolveSystemsRootDirectory() / normalizedPath(target)

proc resolveTargetServiceDirectory*(target: string, source: string): string =
    return resolveServiceDirectory(target) / lastPathPart(source)

proc resolveTargetSystemDirectory*(target: string, source: string): string =
    return resolveSystemDirectory(target) / lastPathPart(source)
