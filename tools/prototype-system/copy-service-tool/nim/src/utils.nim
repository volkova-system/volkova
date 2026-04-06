
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

proc resolveServicesRootPath*(): string =
    return getRepositoryRootDirectory() / servicesDirectory

proc resolveSystemsRootPath*(): string =
    return getRepositoryRootDirectory() / systemsDirectory

proc resolveServiceDirectory*(servicePath: string): string =
    return resolveServicesRootPath() / normalizedPath(servicePath)

proc resolveSystemDirectory*(systemPath: string): string =
    return resolveSystemsRootPath() / normalizedPath(systemPath)
