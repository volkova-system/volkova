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

proc resolveInterfacesRootDirectory*(): string =
    return getRepositoryRootDirectory() / targetRootDirectory

proc resolveInterfaceSourceDirectory*(terminalInterface: string): string =
    return resolveInterfacesRootDirectory() / normalizedPath(
            terminalInterface) / sourceDirectory

proc resolveInterfaceMainFile*(terminalInterface: string): string =
    return resolveInterfaceSourceDirectory(terminalInterface) / mainFile

proc resolveInterfaceTargetBuildDirectory*(terminalInterface: string): string =
    return resolveInterfacesRootDirectory() / normalizedPath(
            terminalInterface) / targetBuildDirectory

proc resolveExecutableExtension*(): string =
    when defined(windows):
        return ".exe"
    else:
        return ""

proc resolveExecutableInterfaceFile*(terminalInterface: string): string =
    let interfaceTargetBuildDirectory = resolveInterfaceTargetBuildDirectory(terminalInterface)
    let buildDirectory = interfaceTargetBuildDirectory / getCurrentPlatform()
    let executableFile = lastPathPart(terminalInterface) &
            resolveExecutableExtension()

    return buildDirectory / executableFile
