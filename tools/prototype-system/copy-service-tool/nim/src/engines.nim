
import os
import utils

proc copyService*(source: string, target: string, systems: bool): string =

    ## Copy source directory inside the target service directory
    ## Args: source - Source service path relative to services
    ##       target - Target service path relative to services or systems
    ##       systems - If target path is relative to systems
    ## Returns: Absolute path to created destination

    let sourceDirectory = utils.resolveServiceDirectory(source)

    var targetDirectory = ""
    if systems:
        targetDirectory = utils.resolveSystemDirectory(target)
    else:
        targetDirectory = utils.resolveServiceDirectory(target)

    let targetOutputDirectory = normalizedPath(targetDirectory / source)


    if dirExists(targetOutputDirectory):
        removeDir(normalizedPath())

    # Perform the copy operation
    copyDirWithPermissions(srcAbs, dstAbs)
    return dstAbs
