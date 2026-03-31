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

proc resolveToolDir*(toolName: string): string =
    ## Resolve tool directory by name, searching recursively if needed
    ## Args: toolName - Name of the tool directory
    ## Returns: Absolute path to tool directory
    let tools = toolsRoot()
    let direct = absolutePath(tools / toolName)
    if dirExists(direct):
        return direct
    var found = ""
    for path in walkDirRec(tools):
        if dirExists(path) and lastPathPart(path) == toolName:
            found = absolutePath(path)
            break
    if found == "":
        raise newException(OSError, "Tool directory not found: " & toolName)
    return found
