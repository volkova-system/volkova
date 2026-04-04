
import os
import utils

proc copyInterface*(source: string, target: string, systems: bool): string =

    ## Copy source directory inside the target interface directory
    ## Args: source - Source interface path relative to interfaces
    ##       target - Target interface path relative to interfaces or systems
    ##       systems - If target path is relative to systems
    ## Returns: Absolute path to created destination

    let sourceDirectory = utils.resolveInterfaceDirectory(source)

    var targetDirectory = ""
    if systems:
        targetDirectory = utils.resolveSystemDirectory(target)
    else:
        targetDirectory = utils.resolveInterfaceDirectory(target)

    let targetOutputDirectory = normalizedPath(targetDirectory / lastPathPart(source))

    if dirExists(targetOutputDirectory):
        removeDir(targetOutputDirectory)

    copyDirWithPermissions(sourceDirectory, targetOutputDirectory)

    return targetOutputDirectory
