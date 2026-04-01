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

proc resolveToolFilePath*(toolFilePath: string, currentToolFile: string = ""): string =
    ## Resolve a tool file path to an absolute path
    ## Paths starting with "./" are relative to the parent directory of currentToolFile
    ## If currentToolFile is empty, paths are relative to the project root
    ## Checks file existence and returns the first valid path found
    ## Args: toolFilePath - Tool file path (relative or absolute)
    ##       currentToolFile - Path to the current tool file (optional)
    ## Returns: Absolute path to the tool file
    ##
    let normalized = toolFilePath.replace("\\", "/")

    if isAbsolute(normalized):
        let absPath = absolutePath(normalized)
        if fileExists(absPath):
            return absPath

    # If absolute path doesn't exist, continue with relative resolution
    if normalized.startsWith("./") or not isAbsolute(normalized):
        # Try relative to current tool file directory first
        if currentToolFile != "":
            let parentDir = parentDir(absolutePath(currentToolFile))
            let relativePath = absolutePath(parentDir / normalized)
            if fileExists(relativePath):
                return relativePath

        # Fallback to project root
        let root = findRoot()
        let rootPath = absolutePath(root / normalized)
        if fileExists(rootPath):
            return rootPath

    raise newException(IOError, "tool file path not found")

