
import os, strutils, osproc

proc getRepositoryRootDirectory*(): string =

    ## Find repository root directory using git repository detection
    ## Returns: Absolute path to repository root directory (git repository root)

    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        let repositoryRootPath = output.strip()
        if repositoryRootPath != "" and dirExists(repositoryRootPath):
            return absolutePath(repositoryRootPath)

        raise newException(OSError,
            "repository root directory not found, " & repositoryRootPath)

    raise newException(OSError,
        "cannot determine repository root directory path")

proc getProcessCurrentDirectory*(): string =

    ## Get the current directory of the process
    ## Returns: Absolute path to the current directory of the process

    let processCurrentDirectory = getCurrentDir()
    if processCurrentDirectory != "" and dirExists(processCurrentDirectory):
        return absolutePath(processCurrentDirectory)

    raise newException(OSError,
        "cannot determine process current directory")

proc resolveToolFilePath*(
        toolFile: string,
        currentToolFile: string = ""
    ): string =

    ## Resolve a tool file path to an absolute path
    ## Paths starting with "./" are relative to the parent directory of currentToolFile
    ## If currentToolFile is empty, paths are relative to the project root
    ## Checks file existence and returns the first valid path found
    ## Args: toolFilePath - Tool file path (relative or absolute)
    ##       currentToolFile - Path to the current tool file (optional)
    ## Returns: Absolute path to the tool file

    let toolFilePath = normalizedPath(toolFile)

    if currentToolFile != "":
        if fileExists(parentDir(currentToolFile) / toolFilePath):
            return parentDir(currentToolFile) / toolFilePath

    if fileExists(getRepositoryRootDirectory() / toolFilePath):
        return getRepositoryRootDirectory() / toolFilePath

    if fileExists(getProcessCurrentDirectory() / toolFilePath):
        return getProcessCurrentDirectory() / toolFilePath

    raise newException(OSError, "tool file path not found")

