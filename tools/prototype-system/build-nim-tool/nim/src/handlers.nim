
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

proc validateCommand*(
        command: string,
        parameters: seq[string]
    ): ValidationResult =

    ## Validate build-nim command and parameters
    ## Args: command - Command name (should be "build-nim")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != buildCommand:
        return ValidationResult(
            status: false,
            issue: "invalid command, '" & command & "'"
        )

    if parameters.len != 1:
        return ValidationResult(
            status: false,
            issue: "invalid parameter count, " & $parameters.len
        )

    let tool = parameters[0]

    if tool == "":
        return ValidationResult(
            status: false,
            issue: "empty tool"
        )

    return ValidationResult(
        status: true,
        tool: tool,
        issue: ""
    )

proc validateToolStructure*(tool: string): ValidationResult =

    var toolSourcePath = ""
    try:
        toolSourcePath = utils.resolveToolSourceDirectory(tool)
    except CatchableError as issue:
        return ValidationResult(
            status: false,
            issue: "tool source directory, " & tool & ", resolution issue, " & issue.msg
        )

    var toolTargetPath = ""
    try:
        toolTargetPath = utils.resolveToolTargetBuildDirectory(tool)
    except CatchableError as issue:
        return ValidationResult(
            status: false,
            issue: "tool target directory, " & tool & ", resolution issue, " & issue.msg
        )

    if not fileExists(toolSourcePath / mainFile):
        return ValidationResult(
            status: false,
            issue: "tool source main file not found, " & tool
        )

    if not dirExists(toolTargetPath / utils.getCurrentPlatform()):
        return ValidationResult(
            status: false,
            issue: "tool target platform directory not found, " & tool
        )

    return ValidationResult(
        status: true,
        tool: tool,
        issue: ""
    )



