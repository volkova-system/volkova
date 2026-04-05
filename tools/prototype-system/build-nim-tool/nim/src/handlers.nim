
import os
import models, settings, utils

proc checkHelpFlag*(flag: string): bool =

    ## Check if argument is a help flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a help flag

    return flag in ["-h", "--help", "help"]

proc checkCommandHelpFlag*(parameters: seq[string]): bool =

    ## Check if arguments contain command help flag
    ## Args: parameters - List of arguments to check
    ## Returns: Boolean true if help flag found

    for parameter in parameters:
        if checkHelpFlag(parameter):
            return true

    return false

proc checkVersionFlag*(flag: string): bool =

    ## Check if argument is a version flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a version flag

    return flag in ["-v", "--version", "version"]

proc checkCommandVersionFlag*(parameters: seq[string]): bool =

    ## Check if arguments contain command version flag
    ## Args: parameters - List of arguments to check
    ## Returns: Boolean true if version flag found

    for parameter in parameters:
        if checkVersionFlag(parameter):
            return true

    return false

proc resolveCommand*(command: string): string =

    ## Resolve command name to internal command
    ## Args: command - Command name from user input
    ## Returns: Resolved command name or empty string if invalid

    let validCommands = @[buildCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =

    ## Validate build-nim command and parameters
    ## Args: command - Command name (should be "build-nim")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

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

    let tool = session.parameters[0]

    if tool == "":
        return ToolSession(
            status: false,
            issue: "empty tool"
        )

    return ToolSession(
        status: true,
        tool: tool,
        issue: ""
    )

proc validateToolStructure*(session: ToolSession): ToolSession =

    var toolSourcePath = ""
    try:
        toolSourcePath = utils.resolveToolSourceDirectory(session.tool)
    except CatchableError as issue:
        return ToolSession(
            status: false,
            issue: "tool source directory, " & session.tool & ", resolution issue, " & issue.msg
        )

    var toolTargetPath = ""
    try:
        toolTargetPath = utils.resolveToolTargetBuildDirectory(session.tool)
    except CatchableError as issue:
        return ToolSession(
            status: false,
            issue: "tool target directory, " & session.tool & ", resolution issue, " & issue.msg
        )

    var mainFilePath = utils.resolveExecutableToolFile(session.tool)

    if not fileExists(toolSourcePath / mainFile):
        return ToolSession(
            status: false,
            issue: "tool source main file not found, " & session.tool
        )

    if not dirExists(toolTargetPath / utils.getCurrentPlatform()):
        return ToolSession(
            status: false,
            issue: "tool target platform directory not found, " & session.tool
        )

    return ToolSession(
        status: true,
        tool: session.tool,
        issue: ""
    )



