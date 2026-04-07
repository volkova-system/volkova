
import os
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

proc validateSourceToolExecutable(session: ToolSession): ToolSession =
    let sourceToolExecutable = resolveSourceToolExecutable(session.source)
    if not fileExists(sourceToolExecutable):
        return ToolSession(
            status: false,
            issue: "source tool executable not found, " & sourceToolExecutable
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target,
        sourceExecutable: sourceToolExecutable
    )

proc validateTargetToolDirectory(session: ToolSession): ToolSession =
    let targetToolsDirectory = resolveTargetToolsDirectory(session.target)

    if not dirExists(targetToolsDirectory):
        return ToolSession(
            status: false,
            issue: "target tools directory not found, " & targetToolsDirectory
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target,
        sourceExecutable: session.sourceExecutable,
        targetExecutable: resolveTargetToolExecutable(session.target, session.source)
    )

proc validatePaths*(session: ToolSession): ToolSession =
    return session |>
        validateSourceToolExecutable() |>
        validateTargetToolDirectory()

proc validateTargetToolExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.targetExecutable):
        return ToolSession(
            status: false,
            issue: "target tool executable not found, " & session.targetExecutable
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target,
        sourceExecutable: session.sourceExecutable,
        targetExecutable: session.targetExecutable
    )
