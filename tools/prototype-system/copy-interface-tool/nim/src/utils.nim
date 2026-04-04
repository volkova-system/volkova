
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

proc getInterfacesRootPath*(): string =

    ## Get absolute path to interfaces directory
    ## Returns: Absolute path to interfaces root directory

    let interfacesRootPath = absolutePath(findRoot() / interfacesDirectory)

    if dirExists(interfacesRootPath):
        return interfacesRootPath

    raise newException(OSError,
        "interfaces root path not found, " & interfacesRootPath)

proc getSystemsRootPath*(): string =

    ## Get absolute path to systems directory
    ## Returns: Absolute path to systems root directory

    let systemsRootPath = absolutePath(findRoot() / systemsDirectory)

    if dirExists(systemsRootPath):
        return systemsRootPath

    raise newException(OSError,
        "systems root path not found, " & systemsRootPath)

proc resolveInterfaceDirectory*(interfacePath: string): string =

    ## Resolve interface directory by relative path
    ## Args: interfacePath - Relative interface path under interfaces directory
    ## Returns: Absolute path to interface directory

    let interfacesAbsolutePath = absolutePath(
        getInterfacesRootPath() / normalizedPath(interfacePath)
    )

    if dirExists(interfacesAbsolutePath):
        return interfacesAbsolutePath

    raise newException(OSError,
        "interface absolute directory not found, " & interfacesAbsolutePath)

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
