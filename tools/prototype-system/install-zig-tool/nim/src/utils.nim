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
    let installDirectory = absolutePath(getHomeDir() / ".local" / "bin")

    if not dirExists(installDirectory):
        createDir(installDirectory)

    return installDirectory

proc resolveInterfacesRootDirectory*(): string =
    return getRepositoryRootDirectory() / interfacesDirectory

proc resolveCliTargetBuildDirectory*(cli: string): string =
    return resolveInterfacesRootDirectory() / normalizedPath(cli) / targetBuildDirectory

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableToolFile*(tool: string): string =
    let cliTargetBuildDirectory = resolveCliTargetBuildDirectory(tool)
    let buildDirectory = cliTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(tool) & resolveExecutableExtension()

    return buildDirectory / executableFile
