
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

proc resolveServiceDirectory*(servicePath: string): string =
    return resolveServicesRootDirectory() / normalizedPath(servicePath)

proc resolveServiceSourceDirectory*(servicePath: string): string =
    return resolveServiceDirectory(servicePath) / sourceDirectory

proc resolveServiceMainFile*(servicePath: string): string =
    return resolveServiceSourceDirectory(servicePath) / mainFile

proc resolveServiceTargetBuildDirectory*(servicePath: string): string =
    return resolveServiceDirectory(servicePath) / targetBuildDirectory

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableServiceFile*(servicePath: string): string =
    let serviceTargetBuildDirectory = resolveServiceTargetBuildDirectory(servicePath)
    let buildDirectory = serviceTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(servicePath) & resolveExecutableExtension()

    return buildDirectory / executableFile
