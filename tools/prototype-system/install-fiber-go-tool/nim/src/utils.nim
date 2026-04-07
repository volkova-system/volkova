
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

proc getArchiveDirectory*(): string =
    if not dirExists(archiveDirectory):
        createDir(archiveDirectory)

    return archiveDirectory

proc resolveServicesRootDirectory*(): string =
    return getRepositoryRootDirectory() / servicesDirectory

proc resolveServiceTargetBuildDirectory*(service: string): string =
    return resolveServicesRootDirectory() / normalizedPath(service) / targetBuildDirectory

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableServiceFile*(service: string): string =
    let serviceTargetBuildDirectory = resolveServiceTargetBuildDirectory(service)
    let buildDirectory = serviceTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(service) & resolveExecutableExtension()

    return buildDirectory / executableFile

