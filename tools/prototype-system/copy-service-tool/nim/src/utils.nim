# Utility procedures for copy-service tool

import os, strutils, osproc
import setting

proc findRoot*(): string =
    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)

    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        let repositoryRootPath = output.strip()
        if repositoryRootPath != "" and dirExists(repositoryRootPath):
            return absolutePath(repositoryRootPath)

    raise newException(IOError, "repository root not found")

proc getServicesRootPath*(): string =
    ## Get absolute path to services directory
    ## Returns: Absolute path to services directory

    let root = findRoot()
    let servicesPath = root / servicesDirectory

    return absolutePath(servicesPath)

proc getSystemsRootPath*(): string =
    ## Get absolute path to systems directory
    ## Returns: Absolute path to systems directory

    let root = findRoot()
    let systemsPath = root / systemsDirectory

    return absolutePath(systemsPath)

proc resolveServicesDirectory*(servicePath: string): string =
    ## Resolve service directory by relative path
    ## Args: servicePath - Relative service path under services directory
    ## Returns: Absolute path to service directory

    let services = getServicesRootPath()
    let servicesAbsolutePath = absolutePath(services / servicePath.replace("\\", "/"))

    if dirExists(servicesAbsolutePath):
        return servicesAbsolutePath

    raise newException(OSError, "service directory not found: " & servicesAbsolutePath)

proc resolveSystemsDirectory*(systemsPath: string): string =
    ## Resolve systems directory by relative path
    ## Args: systemsPath - Relative systems path under systems directory
    ## Returns: Absolute path to systems directory

    let systems = getSystemsRootPath()
    let systemsAbsolutePath = absolutePath(systems / systemsPath.replace("\\", "/"))

    if dirExists(systemsAbsolutePath):
        return systemsAbsolutePath

    raise newException(OSError, "systems absolute directory path not found: " & systemsAbsolutePath)
