
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

    let service = session.parameters[0]

    if service == "":
        return ToolSession(
            status: false,
            issue: "empty service"
        )

    return ToolSession(
        status: true,

        service: service
    )

proc validateExecutable*(session: ToolSession): ToolSession =
    let executableFile = utils.resolveExecutableServiceFile(session.service)
    if not fileExists(executableFile):
        return ToolSession(
            status: false,
            issue: "tool executable not found, " & executableFile
        )

    let installDirectory = utils.getInstallDirectory()
    if not dirExists(installDirectory):
        return ToolSession(
            status: false,
            issue: "tool install directory not found, " & installDirectory
        )

    return ToolSession(
        status: true,

        service: session.service,
        executable: executableFile,
        target: installDirectory / lastPathPart(executableFile)
    )

proc validateInstalledExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.target):
        return ToolSession(
            status: false,
            issue: "installed service not found, " & session.target
        )

    return session

