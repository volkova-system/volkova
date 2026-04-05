
import os, strutils
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

    let validCommands = @[runCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(
        command: string,
        parameters: seq[string]
    ): ValidationResult =

    ## Validate run command and parameters
    ## Args: command - Command name (should be "run")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != runCommand:
        return ValidationResult(
            status: false,
            issue: "invalid command, '" & command & "'"
        )

    if parameters.len != 1:
        return ValidationResult(
            status: false,
            issue: "invalid parameter count, " & $parameters.len
        )

    let toolFilePath = parameters[0]

    if toolFilePath == "":
        return ValidationResult(
            status: false,
            issue: "empty tool file path"
        )

    return ValidationResult(
        status: true,
        target: toolFilePath,
        issue: ""
    )

proc validateToolFile*(toolFilePath: string): ValidationResult =

    if not toolFilePath.endsWith(toolFileExtension):
        return ValidationResult(
            status: false,
            issue: "invalid tool file extension, " & toolFilePath
        )

    let toolFile = utils.resolveToolFilePath(toolFilePath)

    if not fileExists(toolFile):
        return ValidationResult(
            status: false,
            issue: "tool file not found, " & toolFile
        )

    return ValidationResult(
        status: true,
        target: toolFile,
        issue: ""
    )
