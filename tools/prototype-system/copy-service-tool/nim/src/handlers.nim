
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

proc checkSystemsFlag*(flag: string): bool =

    ## Check if argument is a systems flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a systems flag

    return flag in ["-s", "--systems", "systems"]

proc checkCommandSystemsFlag*(parameters: seq[string]): bool =

    ## Check if arguments contain command version flag
    ## Args: parameters - List of arguments to check
    ## Returns: Boolean true if systems flag found

    for parameter in parameters:
        if checkSystemsFlag(parameter):
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

proc validateCommand*(command: string, parameters: seq[
        string]): ValidationResult =

    ## Validate copy-service command and parameters
    ## Args: command - Command name (should be "copy-service")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != copyServiceCommand:
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

    var systems = false
    if checkCommandSystemsFlag(parameters):
        target = parameters[2]
        systems = true

    if source == "" or target == "":
        return ValidationResult(
            status: false,
            issue: "source and target paths cannot be empty"
        )

    return ValidationResult(
        status: true,
        source: source,
        systems: systems,
        target: target,
        issue: ""
    )

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

    var serviceDirectory = absolutePath(servicePath)

    if not dirExists(serviceDirectory):
        try:
            serviceDirectory = utils.resolveServiceDirectory(servicePath)
        except OSError as issue:
            return ValidationResult(
                status: false,
                issue: "target service directory validation failed, " &
                servicePath & ", " & issue.msg
            )

    if lastPathPart(serviceDirectory) != "services" and
            not serviceDirectory.endsWith("-service"):
        return ValidationResult(
            status: false,
            issue: "invalid target service directory, " & servicePath
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

    var systemDirectory = absolutePath(systemPath)

    if not dirExists(systemDirectory):
        try:
            systemDirectory = utils.resolveSystemDirectory(systemPath)
        except OSError:
            return ValidationResult(
                status: false,
                issue: "target system directory validation failed, " & systemPath
            )

    echo "last part " & lastPathPart(systemDirectory)
    echo "ends with " & $systemDirectory.endsWith("-service")

    if lastPathPart(systemDirectory) != "services" and (
            not systemDirectory.endsWith("-service")):
        return ValidationResult(
            status: false,
            issue: "invalid target systems service directory, " & systemPath
        )

    return ValidationResult(
        status: true,
        source: "",
        target: systemPath,
        issue: ""
    )

proc validatePaths*(
        source: string,
        target: string,
        systems: bool
    ): ValidationResult =

    ## Validate source and target paths
    ## Args: source - Source path relative to services
    ##       target - Target path relative to services or systems
    ##       systems - If target path is relative to systems
    ## Returns: ValidationResult with validation status

    var valid = validateSourceServiceStructure(source)

    if not valid.status:
        return valid

    if systems:
        valid = validateTargetSystemStructure(target)
    else:
        valid = validateTargetServiceStructure(target)

    if not valid.status:
        return valid

    return ValidationResult(
        status: true,
        source: source,
        systems: systems,
        target: target,
        issue: ""
    )


