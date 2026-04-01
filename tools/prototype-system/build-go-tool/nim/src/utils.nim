# Utility procedures for build-go tool

import os, strutils, osproc
import setting

proc findRoot*(): string =
    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")
    if exitCode == 0:
        let gitRoot = output.strip()
        if gitRoot != "" and dirExists(gitRoot):
            return absolutePath(gitRoot)
    raise newException(IOError, "repository root not found")

proc servicesRoot*(): string =
    ## Get absolute path to services directory
    ## Returns: Absolute path to services directory
    let root = findRoot()
    let servicesPath = root / servicesDirectory
    return absolutePath(servicesPath)

proc resolveServiceDir*(servicePath: string): string =
    ## Resolve service directory by relative path 'name-system/name-service'
    ## Args: servicePath - Relative service path under services directory
    ## Returns: Absolute path to service directory
    let services = servicesRoot()
    let normalized = servicePath.replace("\\", "/")
    let segments = normalized.split("/")
    if segments.len != 2:
        raise newException(OSError, "Invalid service path, expected 'name-system/name-service': " & servicePath)
    let direct = absolutePath(services / segments[0] / segments[1])
    if dirExists(direct):
        return direct
    raise newException(OSError, "Service directory not found: " & segments[0] &
            "/" & segments[1])
