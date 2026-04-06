
import os
import models, utils

proc copyInterface*(session: ToolSession): ToolSession =
    let sourceDirectory = utils.resolveInterfaceDirectory(session.source)

    var targetDirectory = ""
    if session.systems:
        targetDirectory = utils.resolveSystemDirectory(session.target)
    else:
        targetDirectory = utils.resolveInterfaceDirectory(session.target)

    let targetOutputDirectory = normalizedPath(targetDirectory / lastPathPart(session.source))

    if dirExists(targetOutputDirectory):
        removeDir(targetOutputDirectory)

    copyDirWithPermissions(sourceDirectory, targetOutputDirectory)

    return ToolSession(
        status: true,
        source: session.source,
        systems: session.systems,
        target: targetOutputDirectory
    )
