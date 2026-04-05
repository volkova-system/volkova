
import os
import models, settings, utils

proc checkHelpFlag*(flag: string): bool =
    return flag in ["-h", "--help", "help"]

proc checkCommandHelpFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkHelpFlag(parameter):
            return true

    return false

proc checkVersionFlag*(flag: string): bool =
    return flag in ["-v", "--version", "version"]

proc checkCommandVersionFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkVersionFlag(parameter):
            return true

    return false

proc resolveCommand*(command: string): string =
    let validCommands = @[buildCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != buildCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 1:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let tool = session.parameters[0]

    if tool == "":
        return ToolSession(
            status: false,
            issue: "empty tool"
        )

    return ToolSession(
        status: true,
        tool: tool
    )

proc validateToolStructure*(session: ToolSession): ToolSession =
    let toolSourcePath = utils.resolveToolSourceDirectory(session.tool)
    if not dirExists(toolSourcePath):
        return ToolSession(
            status: false,
            issue: "tool source directory not found, " & session.tool
        )

    let mainFilePath = utils.resolveExecutableToolFile(session.tool)
    if not fileExists(mainFilePath):
        return ToolSession(
            status: false,
            issue: "tool source main file not found, " & session.tool
        )

    let toolTargetPath = utils.resolveToolTargetBuildDirectory(session.tool)
    if not dirExists(toolTargetPath):
        return ToolSession(
            status: false,
            issue: "tool target build directory not found, " & session.tool
        )

    if not dirExists(toolTargetPath / utils.getCurrentPlatform()):
        return ToolSession(
            status: false,
            issue: "tool target build platform directory not found, " & session.tool
        )

    return ToolSession(
        status: true,
        tool: session.tool,
        source: toolSourcePath,
        main: mainFilePath,
        executable: utils.resolveExecutableToolFile(session.tool)
    )

proc validateExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.executable):
        return ToolSession(
            status: false,
            issue: "tool executable not found, " & session.tool
        )

    return ToolSession(
        status: true,
        executable: session.executable
    )



