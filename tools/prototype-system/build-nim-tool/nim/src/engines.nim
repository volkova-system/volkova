
import os, osproc, strutils
import settings, utils

proc formatToolSource*(source: string) =

    ## Format all Nim source files in source directory using nimpretty
    ## Args: source - Source directory path

    for path in walkDirRec(source):
        if path.endsWith(".nim"):
            let (output, exitCode) = execCmdEx(
                "nimpretty --indent:4 \"" & path & "\""
            )

            if exitCode != 0:
                raise newException(OSError,
                    "format tool source failed, " & output)

proc buildTool*(tool: string): string =

    ## Build Nim tool executable for current platform
    ## Args: tool - Tool namespace
    ## Returns: Absolute path to created executable

    let toolSourceDirectory = utils.resolveToolSourceDirectory(tool)
    let toolTargetBuildDirectory = utils.resolveToolTargetBuildDirectory(tool)

    formatToolSource(toolSourceDirectory)

    let mainFilePath = toolSourceDirectory / mainFile
    let buildDirectory = (
        toolTargetBuildDirectory / utils.getCurrentPlatform()
    )
    let executableFilePath = (
        buildDirectory / lastPathPart(tool) & utils.getExecutableExtension()
    )

    let (output, exitCode) = execCmdEx(
        "nim compile -d:release --out:" & executableFilePath & " " & mainFilePath
    )

    if exitCode != 0:
        raise newException(OSError, "build tool failed, " & output)

    return executableFilePath
