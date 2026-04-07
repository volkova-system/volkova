
import os, strutils, osproc
import settings

proc getCurrentPlatform*(): string =
    when defined(windows):
        return "windows"
    elif defined(linux):
        return "linux"
    elif defined(macosx):
        return "darwin"
    else:
        raise newException(OSError, "unsupported platform")

proc getRepositoryRootDirectory*(): string =
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
    let processCurrentDirectory = getCurrentDir()
    if processCurrentDirectory != "" and dirExists(processCurrentDirectory):
        return absolutePath(processCurrentDirectory)

    raise newException(OSError,
        "cannot determine process current directory")

proc resolveToolsRootDirectory*(): string =
    return getRepositoryRootDirectory() / toolsDirectory

proc resolveScriptsRootDirectory*(): string =
    return getRepositoryRootDirectory() / scriptsDirectory

proc getToolFilePath*(
        toolFile: string,
        currentToolFile: string = ""
    ): string =
    let toolFilePath = normalizedPath(toolFile)

    if currentToolFile != "":
        if fileExists(parentDir(currentToolFile) / toolFilePath):
            return parentDir(currentToolFile) / toolFilePath

    if fileExists(getRepositoryRootDirectory() / toolFilePath):
        return getRepositoryRootDirectory() / toolFilePath

    if fileExists(getProcessCurrentDirectory() / toolFilePath):
        return getProcessCurrentDirectory() / toolFilePath

    raise newException(OSError, "tool file path not found")

proc getPowerShellScriptPath*(scriptFile: string): string =
    var scriptFilePath = absolutePath(normalizedPath(scriptFile))
    if fileExists(scriptFilePath):
        return scriptFilePath

    scriptFilePath = resolveScriptsRootDirectory() / normalizedPath(scriptFile)
    if fileExists(scriptFilePath):
        return scriptFilePath

    raise newException(OSError, "script file path not found")
