
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

    ## Check if arguments contain command systems flag
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

    let validCommands = @[copyInterfaceCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(command: string, parameters: seq[
        string]): ValidationResult =

    ## Validate copy-interface command and parameters
    ## Args: command - Command name (should be "copy-interface")
    ##       parameters - List of command parameters
    ## Returns: ValidationResult with validation status and parsed parameters

    if command != copyInterfaceCommand:
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

proc validateSourceInterfaceStructure*(interfacePath: string): ValidationResult =

    ## Validate source interface directory structure
    ## Args: interfacePath - Path of the source interface directory
    ## Returns: ValidationResult with validation status

    var interfaceDirectory = ""
    try:
        interfaceDirectory = utils.resolveInterfaceDirectory(interfacePath)
    except OSError:
        return ValidationResult(
            status: false,
            issue: "source interface directory not found, " & interfacePath
        )

    return ValidationResult(
        status: true,
        source: interfacePath,
        target: "",
        issue: ""
    )

proc validateTargetInterfaceStructure*(interfacePath: string): ValidationResult =

    ## Validate target interface directory structure
    ## Args: interfacePath - Path of the target interface directory
    ## Returns: ValidationResult with validation status

    var interfaceDirectory = absolutePath(interfacePath)

    if not dirExists(interfaceDirectory):
        try:
            interfaceDirectory = utils.resolveInterfaceDirectory(interfacePath)
        except OSError as issue:
            return ValidationResult(
                status: false,
                issue: "target interface directory validation failed, " &
                interfacePath & ", " & issue.msg
            )

    if lastPathPart(interfaceDirectory) != "interfaces" and
            not interfaceDirectory.endsWith("-interface"):
        return ValidationResult(
            status: false,
            issue: "invalid target interface directory, " & interfacePath
        )

    return ValidationResult(
        status: true,
        source: "",
        target: interfacePath,
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

    if lastPathPart(systemDirectory) != "interfaces" and
            (not systemDirectory.endsWith("-interface")):
        return ValidationResult(
            status: false,
            issue: "invalid target systems interface directory, " & systemPath
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
    ## Args: source - Source path relative to interfaces
    ##       target - Target path relative to interfaces or systems
    ##       systems - If target path is relative to systems
    ## Returns: ValidationResult with validation status

    var valid = validateSourceInterfaceStructure(source)

    if not valid.status:
        return valid

    if systems:
        valid = validateTargetSystemStructure(target)
    else:
        valid = validateTargetInterfaceStructure(target)

    if not valid.status:
        return valid

    return ValidationResult(
        status: true,
        source: source,
        systems: systems,
        target: target,
        issue: ""
    )


