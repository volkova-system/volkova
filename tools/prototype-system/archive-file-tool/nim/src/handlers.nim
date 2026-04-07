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
    let validCommands = @[archiveFileCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != archiveFileCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 1:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let source = session.parameters[0]

    if source == "":
        return ToolSession(
            status: false,
            issue: "empty file path"
        )

    return ToolSession(
        status: true,

        source: source
    )

proc validateSourceFile*(session: ToolSession): ToolSession =
    let sourceFile = utils.resolveSourceFile(session.source)

    if not fileExists(sourceFile):
        return ToolSession(
            status: false,
            issue: "source file not found, " & sourceFile
        )

    return ToolSession(
        status: true,

        source: sourceFile,
        target: utils.resolveTargetArchiveFile(session.source)
    )

proc validatePaths*(session: ToolSession): ToolSession =
    return session |>
        validateSourceFile()

proc validateTargetArchivedFile*(session: ToolSession): ToolSession =
    if not fileExists(session.target):
        return ToolSession(
            status: false,
            issue: "target archived file not found, " & session.target
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target
    )
