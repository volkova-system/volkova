
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
    let validCommands = @[archiveDirectoryCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != archiveDirectoryCommand:
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
            issue: "empty directory path"
        )

    return ToolSession(
        status: true,

        source: source,
        target: ""
    )

proc validateSourceDirectory*(session: ToolSession): ToolSession =
    let sourceDirectory = utils.resolveSourceDirectory(session.source)

    if not dirExists(sourceDirectory):
        return ToolSession(
            status: false,
            issue: "source directory not found, " & sourceDirectory
        )

    return ToolSession(
        status: true,

        source: sourceDirectory,
        target: utils.resolveTargetArchiveDirectory(session.source)
    )

proc validateTargetArchiveDirectory*(session: ToolSession): ToolSession =
    let targetParentDirectory = parentDir(session.target)

    if not dirExists(targetParentDirectory):
        createDir(targetParentDirectory)

    if dirExists(session.target):
        return ToolSession(
            status: false,
            issue: "target archive directory already exists, " & session.target
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target
    )

proc validatePaths*(session: ToolSession): ToolSession =
    return session |>
        validateSourceDirectory() |>
        validateTargetArchiveDirectory()

proc validateTargetArchiveExists*(session: ToolSession): ToolSession =
    if not dirExists(session.target):
        return ToolSession(
            status: false,
            issue: "target archive directory not found, " & session.target
        )

    return ToolSession(
        status: true,

        source: session.source,
        target: session.target
    )
