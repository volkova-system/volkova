# Utility procedures for run-tool

import os, strutils, osproc

proc findRoot*(): string =
    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")
    if exitCode == 0:
        let gitRoot = output.strip()
        if gitRoot != "" and dirExists(gitRoot):
            return absolutePath(gitRoot)
    raise newException(IOError, "repository root not found")

proc resolveToolFilePath*(toolFilePath: string): string =
    ## Resolve a tool file path to an absolute path
    ## Paths starting with "./" are relative to the project root
    ## Args: toolFilePath - Tool file path (relative or absolute)
    ## Returns: Absolute path to the tool file
    let root = findRoot()
    let normalized = toolFilePath.replace("\\", "/")
    if normalized.startsWith("./") or not isAbsolute(normalized):
        return absolutePath(root / normalized)
    return absolutePath(normalized)

