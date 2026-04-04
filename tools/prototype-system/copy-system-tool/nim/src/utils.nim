
import os, strutils, osproc
import settings

proc findRoot*(): string =

    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)

    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        let repositoryRootPath = output.strip()
        if repositoryRootPath != "" and dirExists(repositoryRootPath):
            return absolutePath(repositoryRootPath)

        raise newException(OSError,
            "repository root not found, " & repositoryRootPath)

    raise newException(OSError, "cannot determine repository root path")

proc getSystemsRootPath*(): string =

    ## Get absolute path to systems directory
    ## Returns: Absolute path to systems root directory

    let systemsRootPath = absolutePath(findRoot() / systemsDirectory)

    if dirExists(systemsRootPath):
        return systemsRootPath

    raise newException(OSError,
        "systems root path not found, " & systemsRootPath)

proc resolveSystemDirectory*(systemPath: string): string =

    ## Resolve systems directory by relative path
    ## Args: systemsPath - Relative systems path under systems directory
    ## Returns: Absolute path to systems directory

    let systemsAbsolutePath = absolutePath(
        getSystemsRootPath() / normalizedPath(systemPath)
    )

    if dirExists(systemsAbsolutePath):
        return systemsAbsolutePath

    raise newException(OSError,
        "systems absolute directory path not found, " & systemsAbsolutePath)
