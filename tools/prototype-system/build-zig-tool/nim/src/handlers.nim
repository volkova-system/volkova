
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

proc validateInterfaceStructure*(session: ToolSession): ToolSession =
    let interfaceSourcePath = utils.resolveInterfaceSourceDirectory(session.terminalInterface)
    if not dirExists(interfaceSourcePath):
        return ToolSession(
            status: false,
            issue: "interface source directory not found, " & session.terminalInterface
        )

    let mainFilePath = utils.resolveInterfaceMainFile(session.terminalInterface)
    if not fileExists(mainFilePath):
        return ToolSession(
            status: false,
            issue: "interface source main file not found, " & session.terminalInterface
        )

    let interfaceTargetPath = utils.resolveInterfaceTargetBuildDirectory(session.terminalInterface)
    if not dirExists(interfaceTargetPath):
        return ToolSession(
            status: false,
            issue: "interface target build directory not found, " & session.terminalInterface
        )

    if not dirExists(interfaceTargetPath / utils.getCurrentPlatform()):
        return ToolSession(
            status: false,
            issue: "interface target build platform directory not found, " & session.terminalInterface
        )

    return ToolSession(
        status: true,

        terminalInterface: session.terminalInterface,
        source: interfaceSourcePath,
        main: mainFilePath,
        executable: utils.resolveExecutableInterfaceFile(session.terminalInterface)
    )

proc validateExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.executable):
        return ToolSession(
            status: false,
            issue: "tool executable not found, " & session.terminalInterface
        )

    return ToolSession(
        status: true,

        executable: session.executable
    )
