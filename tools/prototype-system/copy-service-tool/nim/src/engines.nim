
import os
import utils

proc copyService*(source: string, target: string): string =

    ## Copy directory from source to destination within services
    ## Args: source - Source service path relative to services
    ##       target - Target service path relative to services or systems
    ## Returns: Absolute path to created destination



    let services = utils.getServicesRootPath()
    let srcAbs = absolutePath(services / srcRel)
    let dstDirAbs = absolutePath(dstRel)
    let srcName = lastPathPart(srcAbs)
    let dstAbs = absolutePath(dstDirAbs / srcName)

    # Create parent directory if needed
    let parent = parentDir(dstAbs)
    if not dirExists(parent):
        createDir(parent)

    if dirExists(dstAbs):
        removeDir(dstAbs)

    # Perform the copy operation
    copyDirWithPermissions(srcAbs, dstAbs)
    return dstAbs
