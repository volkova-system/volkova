
import os, strutils, osproc
import settings

proc getRepositoryRootDirectory*(): string =
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        return output.strip()

    raise newException(OSError,
        "cannot determine repository root directory path")

proc resolveScriptsRootDirectory*(): string =
    return getRepositoryRootDirectory() / scriptsDirectory

proc resolveSystemsRootDirectory*(): string =
    return getRepositoryRootDirectory() / systemsDirectory

proc resolveSourceScriptPath*(scriptFile: string): string =
    return resolveScriptsRootDirectory() / scriptFile

proc resolveTargetScriptsDirectory*(targetScriptsPath: string): string =
    return resolveSystemsRootDirectory() / normalizedPath(targetScriptsPath)

proc resolveTargetScriptPath*(
        targetScriptsPath: string,
        scriptFile: string
    ): string =
    return resolveTargetScriptsDirectory(targetScriptsPath) / scriptFile
