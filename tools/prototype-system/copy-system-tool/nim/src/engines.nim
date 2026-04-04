
import os
import utils

proc copySystem*(source: string, target: string): string =

    ## Copy source directory inside the target system directory
    ## Args: source - Source system path relative to systems
    ##       target - Target system path relative to systems
    ## Returns: Absolute path to created destination

    let sourceDirectory = utils.resolveSystemDirectory(source)

    let targetDirectory = utils.resolveSystemDirectory(target)

    let targetOutputDirectory = normalizedPath(targetDirectory / lastPathPart(source))

    if dirExists(targetOutputDirectory):
        removeDir(targetOutputDirectory)

    copyDirWithPermissions(sourceDirectory, targetOutputDirectory)

    return targetOutputDirectory
