
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

    let terminalInterface = session.parameters[0]

    if terminalInterface == "":
        return ToolSession(
            status: false,
            issue: "empty interface"
        )

    return ToolSession(
        status: true,

        terminalInterface: terminalInterface
    )

proc validateExecutable*(session: ToolSession): ToolSession =
    let executableFile = utils.resolveExecutableToolFile(
            session.terminalInterface)
    if not fileExists(executableFile):
        return ToolSession(
            status: false,
            issue: "interface executable not found, " & executableFile
        )

    let installDirectory = utils.getInstallDirectory()
    if not dirExists(installDirectory):
        return ToolSession(
            status: false,
            issue: "interface install directory not found, " & installDirectory
        )

    return ToolSession(
        status: true,

        terminalInterface: session.terminalInterface,
        executable: executableFile,
        target: installDirectory / lastPathPart(executableFile)
    )

proc validateInstalledExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.target):
        return ToolSession(
            status: false,
            issue: "installed interface not found, " & session.target
        )

    return session
