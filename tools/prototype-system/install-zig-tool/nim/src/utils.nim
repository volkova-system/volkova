# Utility procedures for install-zig tool

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
    raise newException(IOError, "Git repository root not found")

proc interfacesRoot*(): string =
    ## Get absolute path to interfaces directory
    ## Returns: Absolute path to interfaces directory
    let root = findRoot()
    let interfacesPath = root / interfacesDirectory
    return absolutePath(interfacesPath)

proc resolveCliDir*(cliPath: string): string =
    ## Resolve CLI directory by relative path 'name-system/name-cli'
    ## Args: cliPath - Relative CLI path under interfaces directory
    ## Returns: Absolute path to CLI directory
    let interfaces = interfacesRoot()
    let normalized = cliPath.replace("\\", "/")
    let segments = normalized.split("/")
    if segments.len != 2:
        raise newException(OSError, "Invalid CLI path, expected 'name-system/name-cli': " & cliPath)
    let direct = absolutePath(interfaces / segments[0] / segments[1])
    if dirExists(direct):
        return direct
    raise newException(OSError, "CLI directory not found: " & segments[0] &
            "/" & segments[1])
