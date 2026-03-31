# Command handler for run-tool

import os, strutils
import setting
import utils

type
    ValidationResult* = object
        ## Result of parameter validation
        valid*: bool
        toolFilePath*: string
        errorMsg*: string

proc checkHelpFlag*(flag: string): bool =
    ## Check if argument is a help flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a help flag
    return flag in ["-h", "--help", "help"]

proc checkVersionFlag*(flag: string): bool =
    ## Check if argument is a version flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a version flag
    return flag in ["-v", "--version", "version"]

proc checkCommandHelpFlag*(args: seq[string]): bool =
    ## Check if arguments contain command help flag
    ## Args: args - List of arguments to check
    ## Returns: Boolean true if help flag found
    for arg in args:
        if checkHelpFlag(arg):
            return true
    return false

proc resolveCommand*(cmdName: string): string =
    ## Resolve command name to internal command
    ## Args: cmdName - Command name from user input
    ## Returns: Resolved command name or empty string if invalid
    let validCommands = @[commandName]
    if cmdName in validCommands:
        return cmdName
    return ""

proc validateCommand*(cmd: string, args: seq[string]): ValidationResult =
    ## Validate run command and arguments
    ## Args: cmd - Command name (should be "run")
    ##       args - List of command arguments
    ## Returns: ValidationResult with validation status and parsed parameters

    # Validate command name
    if cmd != commandName:
        return ValidationResult(
          valid: false,
          errorMsg: "Invalid command '" & cmd & "'"
        )

    # Validate argument count
    if args.len != 1:
        return ValidationResult(
          valid: false,
          errorMsg: "Expected 1 argument, got " & $args.len
        )

    # Extract tool file path
    let toolFilePathArg = args[0]

    # Validate tool file path is not empty
    if toolFilePathArg == "":
        return ValidationResult(
          valid: false,
          errorMsg: "Tool file path cannot be empty"
        )

    # Validate tool file extension
    if not toolFilePathArg.endsWith(toolFileExtension):
        return ValidationResult(
          valid: false,
          errorMsg: "Tool file must have " & toolFileExtension &
              " extension: " & toolFilePathArg
        )

    # Resolve to absolute path
    let resolvedPath = utils.resolveToolFilePath(toolFilePathArg)

    # Validate tool file exists
    if not fileExists(resolvedPath):
        return ValidationResult(
          valid: false,
          errorMsg: "Tool file not found: " & resolvedPath
        )

    return ValidationResult(
      valid: true,
      toolFilePath: resolvedPath,
      errorMsg: ""
    )
