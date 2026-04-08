
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

proc resolveInterfacesRootDirectory*(): string =
    return getRepositoryRootDirectory() / interfacesDirectory

proc resolveSystemsRootDirectory*(): string =
    return getRepositoryRootDirectory() / systemsDirectory

proc resolveInterfaceDirectory*(interfacePath: string): string =
    return resolveInterfacesRootDirectory() / normalizedPath(interfacePath)

proc resolveSystemDirectory*(systemPath: string): string =
    return resolveSystemsRootDirectory() / normalizedPath(systemPath)

proc resolveInterfaceSuffix*(interfacePath: string): string =
    return interfacePath.split("-")[^1]

proc resolveTargetInterfaceDirectory*(target: string, source: string): string =
    return resolveInterfaceDirectory(target) / lastPathPart(source)

proc resolveTargetSystemDirectory*(target: string, source: string): string =
    return resolveSystemDirectory(target) / lastPathPart(source)
