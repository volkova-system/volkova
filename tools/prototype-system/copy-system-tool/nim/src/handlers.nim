
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

proc resolveCommand*(command: string): string =
    let validCommands = @[copySystemCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != copySystemCommand:
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
        target: target
    )

proc validateSourceSystemDirectory*(session: ToolSession): ToolSession =
    let systemDirectory = utils.resolveSystemDirectory(session.source)

    if not dirExists(systemDirectory):
        return ToolSession(
            status: false,
            issue: "source system directory not found, " & systemDirectory
        )

    return ToolSession(
        status: true,

        source: systemDirectory,
        target: session.target
    )

proc validateTargetSystemDirectory*(session: ToolSession): ToolSession =
    let systemDirectory = utils.resolveSystemDirectory(session.target)

    if not dirExists(systemDirectory):
        return ToolSession(
            status: false,
            issue: "target system directory not found, " & systemDirectory
        )

    if lastPathPart(systemDirectory) != systemsDirectory and
        (not systemDirectory.endsWith(systemSuffix)):

        return ToolSession(
            status: false,
            issue: "invalid target system directory, " & systemDirectory
        )

    let targetOutputDirectory = systemDirectory / lastPathPart(session.source)
    if lastPathPart(parentDir(targetOutputDirectory)) != systemsDirectory and
        (not targetOutputDirectory.endsWith(systemSuffix)):
        return ToolSession(
            status: false,
            issue: "invalid target output directory, " & targetOutputDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: targetOutputDirectory
    )

proc validatePaths*(session: ToolSession): ToolSession =
    return session |>
        validateSourceSystemDirectory() |>
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
        target: session.target
    )


