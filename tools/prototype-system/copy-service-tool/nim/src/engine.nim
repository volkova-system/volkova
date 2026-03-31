# Core engine for copy-service tool operations

import os, strutils, osproc
import utils

proc findRoot*(): string =
    ## Find project root using git repository detection
    ## Returns: Absolute path to project root (git repository root)
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")
    if exitCode == 0:
        let gitRoot = output.strip()
        if gitRoot != "" and dirExists(gitRoot):
            return absolutePath(gitRoot)

    raise newException(IOError, "Git repository root not found")

proc servicesRoot*(): string =
    ## Get absolute path to services directory
    ## Returns: Absolute path to services directory
    let root = findRoot()
    let servicesPath = root / servicesDirectory
    return absolutePath(servicesPath)

proc copyDir*(srcRel: string, dstRel: string): string =
    ## Copy directory from source to destination within services
    ## Args: srcRel - Source path relative to services
    ##       dstRel - Destination path relative to services
    ## Returns: Absolute path to created destination
    let services = utils.servicesRoot()
    let srcAbs = absolutePath(services / srcRel)
    let dstDirAbs = absolutePath(services / dstRel)
    let srcName = lastPathPart(srcAbs)
    let dstAbs = absolutePath(dstDirAbs / srcName)

    # Create parent directory if needed
    let parent = parentDir(dstAbs)
    if not dirExists(parent):
        createDir(parent)

    # Perform the copy operation
    copyDirWithPermissions(srcAbs, dstAbs)
    return dstAbs
