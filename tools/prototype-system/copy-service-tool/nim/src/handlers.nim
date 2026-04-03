
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

    let validCommands = @[copyServiceCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(command: string, parameters: seq[string]): ValidationResult =

    ## Validate copy-service command and parameters
    ## Args: command - Command name (should be "copy-service")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != copyServiceCommand:
        return ValidationResult(
            status: false,
            issue: "invalid command, '" & command & "'"
        )

    if parameters.len != 2:
        return ValidationResult(
            status: false,
            issue: "expected 2 parameters, got " & $parameters.len
        )

    let source = parameters[0]
    let target = parameters[1]

    if source == "" or target == "":
        return ValidationResult(
            status: false,
            issue: "source and target paths cannot be empty"
        )

    return ValidationResult(
        status: true,
        source: source,
        target: target,
        issue: ""
    )

proc within(base: string, path: string): bool =

    ## Check if path is within base directory
    ## Args: base - Base directory path
    ##       path - Path to check
    ## Returns: Boolean true if path is within base

    let normalBase = absolutePath(base)
    let normalPath = absolutePath(path)

    return normalPath.startsWith(normalBase)

proc validateSourceServiceStructure*(servicePath: string): ValidationResult =

    ## Validate source service directory structure
    ## Args: servicePath - Path of the source service directory
    ## Returns: ValidationResult with validation status

    var serviceDirectory = ""
    try:
        serviceDirectory = utils.resolveServiceDirectory(servicePath)
    except OSError:
        return ValidationResult(
            status: false,
            issue: "source service directory not found, " & servicePath
        )

    return ValidationResult(
        status: true,
        source: servicePath,
        target: "",
        issue: ""
    )

proc validateTargetServiceStructure*(servicePath: string): ValidationResult =

    ## Validate target service directory structure
    ## Args: servicePath - Path of the target service directory
    ## Returns: ValidationResult with validation status

    var serviceDirectory = ""
    try:
        serviceDirectory = utils.resolveSystemDirectory(servicePath)
    except OSError:
        return ValidationResult(
            status: false,
            issue: "target service directory validation failed, " & servicePath
        )

    return ValidationResult(
        status: true,
        source: "",
        target: servicePath,
        issue: ""
    )

proc validateTargetSystemStructure*(systemPath: string): ValidationResult =

    ## Validate system directory structure
    ## Args: systemPath - Path of the system directory
    ## Returns: ValidationResult with validation status

    var systemDirectory = ""
    try:
        systemDirectory = utils.resolveSystemDirectory(systemPath)
    except OSError:
        return ValidationResult(
            status: false,
            issue: "target system directory validation failed, " & systemPath
        )

    return ValidationResult(
        status: true,
        source: "",
        target: systemPath,
        issue: ""
    )

proc validatePaths*(source: string, target: string): ValidationResult =

    ## Validate source and target paths
    ## Args: source - Source path relative to services
    ##       target - Target path relative to services or systems
    ## Returns: ValidationResult with validation status



    return ValidationResult(
        status: true,
        source: source,
        target: target,
        issue: ""
    )


