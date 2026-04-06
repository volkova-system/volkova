import os
import models, utils

proc copyTool*(session: ToolSession): ToolSession =
    let platform = getCurrentPlatform()
    let sourceDistPath = session.source / distDirectory / platform
    let targetToolsPath = session.target / platform

    if not dirExists(sourceDistPath):
        raise newException(OSError,
            "source dist directory not found, " & sourceDistPath)

    if not dirExists(targetToolsPath):
        createDir(targetToolsPath)

    for file in walkFiles(sourceDistPath / "*"):
        let fileName = extractFilename(file)
        let targetFile = targetToolsPath / fileName

        if fileExists(targetFile):
            removeFile(targetFile)

        copyFile(file, targetFile)

    return session
