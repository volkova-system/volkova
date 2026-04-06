
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

proc checkSystemsFlag*(flag: string): bool =
    return flag in ["-s", "--systems", "systems"]

proc checkCommandSystemsFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkSystemsFlag(parameter):
            return true

    return false

proc resolveCommand*(command: string): string =
    let validCommands = @[copyServiceCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != copyServiceCommand:
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
        target: target
    )

proc validateSourceServiceStructure*(session: ToolSession): ToolSession =
    let serviceDirectory = utils.resolveServiceDirectory(session.source)

    if not dirExists(serviceDirectory):
        return ToolSession(
            status: false,
            issue: "source service directory not found, " & serviceDirectory
        )

    return ToolSession(
        status: true,

        source: serviceDirectory,
        systems: session.systems,
        target: session.target
    )

proc validateTargetServiceStructure*(session: ToolSession): ToolSession =
    let serviceDirectory = utils.resolveServiceDirectory(session.target)

    if not dirExists(serviceDirectory):
        return ToolSession(
            status: false,
            issue: "target service directory not found, " & serviceDirectory
        )

    if lastPathPart(serviceDirectory) != "services" and
        (not serviceDirectory.endsWith("-service")):

        return ToolSession(
            status: false,
            issue: "invalid target service directory, " & serviceDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        systems: session.systems,
        target: serviceDirectory
    )

proc validateTargetSystemStructure*(session: ToolSession): ToolSession =
    let systemDirectory = utils.resolveSystemDirectory(session.target)

    if not dirExists(systemDirectory):
        return ToolSession(
            status: false,
            issue: "target system directory not found, " & systemDirectory
        )

    if lastPathPart(systemDirectory) != "services" and
        (not systemDirectory.endsWith("-service")):

        return ToolSession(
            status: false,
            issue: "invalid target system directory, " & systemDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        systems: session.systems,
        target: systemDirectory
    )

proc validatePaths*(session: ToolSession): ToolSession =
    var validatedSession = validateSourceServiceStructure(session)

    if not validatedSession.status:
        return validatedSession

    if session.systems:
        validatedSession = validateTargetSystemStructure(validatedSession)
    else:
        validatedSession = validateTargetServiceStructure(validatedSession)

    if not validatedSession.status:
        return validatedSession

    return ToolSession(
        status: true,
        command: session.command,
        parameters: session.parameters,
        source: session.source,
        systems: session.systems,
        target: session.target
    )


