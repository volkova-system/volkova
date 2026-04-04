
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

    let validCommands = @[copySystemCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(
        command: string,
        parameters: seq[string]
    ): ValidationResult =

    ## Validate copy-system command and parameters
    ## Args: command - Command name (should be "copy-system")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != copySystemCommand:
        return ValidationResult(
            status: false,
            issue: "invalid command, '" & command & "'"
        )

    if parameters.len < 2 or parameters.len > 3:
        return ValidationResult(
            status: false,
            issue: "expected 2-3 parameters, got " & $parameters.len
        )

    let source = parameters[0]
    var target = parameters[1]

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

proc validateSourceSystemStructure*(systemPath: string): ValidationResult =

    ## Validate source system directory structure
    ## Args: systemPath - Path of the source system directory
    ## Returns: ValidationResult with validation status

    var systemDirectory = ""
    try:
        systemDirectory = utils.resolveSystemDirectory(systemPath)
    except OSError:
        return ValidationResult(
            status: false,
            issue: "source system directory not found, " & systemPath
        )

    return ValidationResult(
        status: true,
        source: systemPath,
        target: "",
        issue: ""
    )

proc validateTargetSystemStructure*(systemPath: string): ValidationResult =

    ## Validate target system directory structure
    ## Args: systemPath - Path of the target system directory
    ## Returns: ValidationResult with validation status

    var systemDirectory = absolutePath(systemPath)

    if not dirExists(systemDirectory):
        try:
            systemDirectory = utils.resolveSystemDirectory(systemPath)
        except OSError as issue:
            return ValidationResult(
                status: false,
                issue: "target system directory validation failed, " &
                systemPath & ", " & issue.msg
            )

    if lastPathPart(systemDirectory) != "systems" and
            not systemDirectory.endsWith("-system"):
        return ValidationResult(
            status: false,
            issue: "invalid target system directory, " & systemPath
        )

    return ValidationResult(
        status: true,
        source: "",
        target: systemPath,
        issue: ""
    )

proc validatePaths*(source: string, target: string): ValidationResult =

    ## Validate source and target paths
    ## Args: source - Source path relative to systems
    ##       target - Target path relative to systems or systems
    ## Returns: ValidationResult with validation status

    var valid = validateSourceSystemStructure(source)

    if not valid.status:
        return valid

    valid = validateTargetSystemStructure(target)

    if not valid.status:
        return valid

    return ValidationResult(
        status: true,
        source: source,
        target: target,
        issue: ""
    )


