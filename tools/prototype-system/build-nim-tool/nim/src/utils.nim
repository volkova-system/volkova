# Utility procedures for build-nim tool

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

proc toolsRoot*(): string =
    ## Get absolute path to tools directory
    ## Returns: Absolute path to tools directory
    let root = findRoot()
    let toolsPath = root / toolsDirectory
    return absolutePath(toolsPath)

proc resolveToolDir*(toolPath: string): string =
    ## Resolve tool directory by relative path 'name-system/name-tool'
    ## Args: toolPath - Relative tool path under tools directory
    ## Returns: Absolute path to tool directory
    let tools = toolsRoot()
    let normalized = toolPath.replace("\\", "/")
    let segments = normalized.split("/")
    if segments.len != 2:
        raise newException(OSError, "Invalid tool path, expected 'name-system/name-tool': " & toolPath)
    let direct = absolutePath(tools / segments[0] / segments[1])
    if dirExists(direct):
        return direct
    raise newException(OSError, "Tool directory not found: " & segments[0] & "/" & segments[1])
