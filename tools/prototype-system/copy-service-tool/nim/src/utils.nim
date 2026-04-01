# Utility procedures for copy-service tool

import os, strutils, osproc
import setting

proc findRoot*(): string =
    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)
    ##
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")
    if exitCode == 0:
        let gitRoot = output.strip()
        if gitRoot != "" and dirExists(gitRoot):
            return absolutePath(gitRoot)

    raise newException(IOError, "repository root not found")

proc servicesRoot*(): string =
    ## Get absolute path to services directory
    ## Returns: Absolute path to services directory
    ##
    let root = findRoot()
    let servicesPath = root / servicesDirectory

    return absolutePath(servicesPath)

proc resolveServiceDir*(servicePath: string): string =
    ## Resolve service directory by relative path
    ## Args: servicePath - Relative service path under services directory
    ## Returns: Absolute path to service directory
    ##
    let services = servicesRoot()
    let normalized = servicePath.replace("\\", "/")
    let direct = absolutePath(services / normalized)

    if dirExists(direct):
        return direct

    raise newException(OSError, "service directory not found: " & servicePath)
