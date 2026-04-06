
import os
import models, utils

proc copyService*(session: ToolSession): ToolSession =
    let sourceDirectory = utils.resolveServiceDirectory(session.source)

    var targetDirectory = ""
    if session.systems:
        targetDirectory = utils.resolveSystemDirectory(session.target)
    else:
        targetDirectory = utils.resolveServiceDirectory(session.target)

    let targetOutputDirectory = normalizedPath(
        targetDirectory / lastPathPart(session.source)
    )

    if dirExists(targetOutputDirectory):
        removeDir(targetOutputDirectory)

    copyDirWithPermissions(sourceDirectory, targetOutputDirectory)

    return ToolSession(
        status: true,
        command: session.command,
        parameters: session.parameters,
        source: session.source,
        systems: session.systems,
        target: targetOutputDirectory
    )
