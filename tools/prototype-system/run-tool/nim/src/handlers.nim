
import os, strutils
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
    let validCommands = @[runCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != runCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 1:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let toolFilePath = session.parameters[0]

    if toolFilePath == "":
        return ToolSession(
            status: false,
            issue: "empty tool file path"
        )

    return ToolSession(
        status: true,

        target: toolFilePath
    )

proc validateToolFile*(session: ToolSession): ToolSession =
    if not session.target.endsWith(toolFileExtension):
        return ToolSession(
            status: false,
            issue: "invalid tool file extension, " & session.target
        )

    let toolFile = utils.getToolFilePath(session.target)

    if not fileExists(toolFile):
        return ToolSession(
            status: false,
            issue: "tool file not found, " & toolFile
        )

    return ToolSession(
        status: true,

        target: toolFile
    )
