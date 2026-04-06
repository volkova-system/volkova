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
    let validCommands = @[copyCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != copyCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 2:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let source = session.parameters[0]
    let target = session.parameters[1]

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

proc validateSourceToolDirectory*(session: ToolSession): ToolSession =
    let sourceToolDirectory = resolveSourceToolDirectory(session.source)

    if not dirExists(sourceToolDirectory):
        return ToolSession(
            status: false,
            issue: "source tool directory not found, " & sourceToolDirectory
        )

    if not (sourceToolDirectory.contains(systemSuffix) and
            sourceToolDirectory.endsWith(toolSuffix)):
        return ToolSession(
            status: false,
            issue: "invalid source tool path, " & sourceToolDirectory
        )

    return ToolSession(
        status: true,

        source: sourceToolDirectory,
        target: session.target
    )

proc validateTargetToolsDirectory*(session: ToolSession): ToolSession =
    let targetToolsDirectory = resolveTargetToolsDirectory(session.target)

    if not dirExists(targetToolsDirectory):
        return ToolSession(
            status: false,
            issue: "target tools directory not found, " & targetToolsDirectory
        )

    if lastPathPart(targetToolsDirectory) != toolsDirectory:
        return ToolSession(
            status: false,
            issue: "invalid target tools directory, " & targetToolsDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: targetToolsDirectory
    )

proc validatePaths*(session: ToolSession): ToolSession =
    var result = session
    result = validateSourceToolDirectory(result)
    if not result.status:
        return result

    result = validateTargetToolsDirectory(result)
    return result

proc validateTargetOutputDirectory*(session: ToolSession): ToolSession =
    let platform = getCurrentPlatform()
    let targetOutputDirectory = session.target / platform

    if not dirExists(targetOutputDirectory):
        return ToolSession(
            status: false,
            issue: "target output directory not found, " & targetOutputDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target
    )
