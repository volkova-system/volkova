
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
    let validCommands = @[installCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != installCommand:
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

proc validateExecutable*(session: ToolSession): ToolSession =
    let executableFile = utils.resolveExecutableToolFile(session.tool)
    if not dirExists(executableFile):
        return ToolSession(
            status: false,
            issue: "tool executable not found, " & executableFile
        )

    let installDirectory = utils.getInstallDirectory()
    if not dirExists(installDirectory):
        return ToolSession(
            status: false,
            issue: "tool executable install directory not found, " & installDirectory
        )

    return ToolSession(
        status: true,
        tool: session.tool,
        executable: executableFile,
        target: installDirectory / lastPathPart(executableFile)
    )

proc validateInstalledExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.target):
        return ToolSession(
            status: false,
            issue: "installed tool executable file not found, " & session.target
        )

proc validateExecutableCommand*(session: ToolSession): ToolSession =

