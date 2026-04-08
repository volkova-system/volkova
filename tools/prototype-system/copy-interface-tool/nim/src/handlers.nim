
import os, strutils
import macros, models, settings, utils

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

proc checkSystemsFlag*(flag: string): bool =
    return flag in ["-s", "--systems", "systems"]

proc checkCommandSystemsFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkSystemsFlag(parameter):
            return true

    return false

proc resolveCommand*(command: string): string =
    let validCommands = @[copyInterfaceCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != copyInterfaceCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len < 2 or session.parameters.len > 3:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let source = session.parameters[0]
    var target = session.parameters[1]

    var systems = false
    if checkCommandSystemsFlag(session.parameters):
        target = session.parameters[2]
        systems = true

    if source == "":
        return ToolSession(
            status: false,
            issue: "empty source path"
        )

    if target == "":
        return ToolSession(
            status: false,
            issue: "empty target path"
        )

    return ToolSession(
        status: true,

        source: source,
        systems: systems,
        targetSuffix: utils.resolveInterfaceSuffix(source),
        target: target
    )

proc validateSourceInterfaceDirectory*(session: ToolSession): ToolSession =
    let interfaceDirectory = utils.resolveInterfaceDirectory(session.source)

    if not dirExists(interfaceDirectory):
        return ToolSession(
            status: false,
            issue: "source interface directory not found, " & interfaceDirectory
        )

    return ToolSession(
        status: true,

        source: interfaceDirectory,
        systems: session.systems,
        targetSuffix: session.targetSuffix,
        target: session.target
    )

proc validateTargetInterfaceDirectory*(session: ToolSession): ToolSession =
    if session.systems:
        return session

    let interfaceDirectory = utils.resolveInterfaceDirectory(session.target)
    if not dirExists(interfaceDirectory):
        return ToolSession(
            status: false,
            issue: "target interface directory not found, " & interfaceDirectory
        )

    if lastPathPart(interfaceDirectory) != interfacesDirectory and
        (not interfaceDirectory.endsWith(session.targetSuffix)):
        return ToolSession(
            status: false,
            issue: "invalid target interface directory, " & interfaceDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        systems: session.systems,
        targetSuffix: session.targetSuffix,
        target: utils.resolveTargetInterfaceDirectory(session.target,
                session.source)
    )

proc validateTargetSystemDirectory*(session: ToolSession): ToolSession =
    if not session.systems:
        return session

    let systemDirectory = utils.resolveSystemDirectory(session.target)
    if not dirExists(systemDirectory):
        return ToolSession(
            status: false,
            issue: "target system directory not found, " & systemDirectory
        )

    if lastPathPart(systemDirectory) != "interfaces" and
        (not systemDirectory.endsWith(session.targetSuffix)):
        return ToolSession(
            status: false,
            issue: "invalid target system directory, " & systemDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        systems: session.systems,
        targetSuffix: session.targetSuffix,
        target: utils.resolveTargetSystemDirectory(session.target,
                session.source)
    )

proc validatePaths*(session: ToolSession): ToolSession =
    return session |>
        validateSourceInterfaceDirectory() |>
        validateTargetInterfaceDirectory() |>
        validateTargetSystemDirectory()

proc validateTargetOutputDirectory*(session: ToolSession): ToolSession =
    if not dirExists(session.target):
        return ToolSession(
            status: false,
            issue: "target output directory not found, " & session.target
        )

    return ToolSession(
        status: true,

        source: session.source,
        systems: session.systems,
        target: session.target
    )


