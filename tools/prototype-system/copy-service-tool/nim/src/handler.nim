# Command handler for copy-service tool

import os, strutils
import setting
import utils

type
    ValidationResult* = object
        status*: bool
        source*: string
        target*: string
        issue*: string

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

proc checkCommandHelpFlag*(parameters: seq[string]): bool =
    ## Check if arguments contain command help flag
    ## Args: parameters - List of arguments to check
    ## Returns: Boolean true if help flag found

    for parameter in parameters:
        if checkHelpFlag(parameter):
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

proc within(base: string, path: string): bool =
    ## Check if path is within base directory
    ## Args: base - Base directory path
    ##       path - Path to check
    ## Returns: Boolean true if path is within base

    let normalBase = absolutePath(base)
    let normalPath = absolutePath(path)

    return normalPath.startsWith(normalBase)

proc validateServiceStructure*(servicePath: string,
        servicesRoot: string): ValidationResult =
    ## Validate service directory structure
    ## Args: servicePath - Path of the service directory
    ##       servicesRoot - Absolute path to services directory
    ## Returns: ValidationResult with validation status

    var serviceDirectory = absolutePath(servicesRoot / servicePath)
    if not dirExists(serviceDirectory):
        try:
            serviceDirectory = utils.resolveServicesDirectory(servicePath)
        except OSError:
            return ValidationResult(
              status: false,
              issue: "service directory not found: " & servicePath
            )

    # Validate service directory exists
    if not dirExists(serviceDirectory):
        return ValidationResult(
          status: false,
          issue: "service directory not found: " & servicePath
        )

    # Validate service is within services directory
    if not within(servicesRoot, serviceDirectory):
        return ValidationResult(
          status: false,
          issue: "service path outside services directory: " & servicePath
        )

    # Return successful validation
    return ValidationResult(
      status: true,
      source: servicePath,
      target: "",
      issue: ""
    )

proc validatePaths*(source: string, target: string): ValidationResult =
    ## Validate source and destination paths
    ## Args: source - Source path relative to services or systems
    ##       target - Target path relative to services or systems
    ## Returns: ValidationResult with validation status

    let servicesRootPath = utils.getServicesRootPath()
    let systemsRootPath = utils.getSystemsRootPath()

    let srcAbs = absolutePath(servicesRootPath / source)

    let dstDirAbs = absolutePath(target)
    let srcName = lastPathPart(srcAbs)
    let dstFinalAbs = absolutePath(dstDirAbs / srcName)

    # Validate source exists and is directory
    if not dirExists(srcAbs):
        return ValidationResult(
          status: false,
          issue: "source directory not found: " & srcRel
        )

    # Validate source is within services directory
    if not within(servicesRoot, srcAbs):
        return ValidationResult(
          status: false,
          issue: "source path outside services directory: " & srcRel
        )

    # Validate destination end child directory is named "services"
    if lastPathPart(dstDirAbs) != servicesDirectory:
        return ValidationResult(
          status: false,
          issue: "target directory must end with '" & servicesDirectory & "': " & dstRel
        )

    # Validate source and target relationship
    if dstFinalAbs == srcAbs:
        return ValidationResult(
          status: false,
          issue: "source and target are identical: " & srcRel
        )

    if dstFinalAbs.startsWith(srcAbs):
        return ValidationResult(
          status: false,
          issue: "target cannot be inside source directory"
        )

    # Return successful validation
    return ValidationResult(
      status: true,
      source: source,
      target: target,
      issue: ""
    )

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
