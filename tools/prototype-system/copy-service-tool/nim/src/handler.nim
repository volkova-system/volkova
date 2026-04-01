# Command handler for copy-service tool

import os, strutils
import setting
import utils

type
    ValidationResult* = object
        ## Result of parameter validation
        valid*: bool
        srcRel*: string
        dstRel*: string
        errorMsg*: string

proc checkHelpFlag*(flag: string): bool =
    ## Check if argument is a help flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a help flag
    ##
    return flag in ["-h", "--help", "help"]

proc checkVersionFlag*(flag: string): bool =
    ## Check if argument is a version flag
    ## Args: flag - The flag to check
    ## Returns: Boolean true if it's a version flag
    ##
    return flag in ["-v", "--version", "version"]

proc checkCommandHelpFlag*(args: seq[string]): bool =
    ## Check if arguments contain command help flag
    ## Args: args - List of arguments to check
    ## Returns: Boolean true if help flag found
    ##
    for arg in args:
        if checkHelpFlag(arg):
            return true

    return false

proc resolveCommand*(cmdName: string): string =
    ## Resolve command name to internal command
    ## Args: cmdName - Command name from user input
    ## Returns: Resolved command name or empty string if invalid
    ##
    let validCommands = @[commandName]

    if cmdName in validCommands:
        return cmdName

    return ""

proc within(base: string, path: string): bool =
    ## Check if path is within base directory
    ## Args: base - Base directory path
    ##       path - Path to check
    ## Returns: Boolean true if path is within base
    ##
    let normalBase = absolutePath(base)
    let normalPath = absolutePath(path)

    return normalPath.startsWith(normalBase)

proc validateServiceStructure*(servicePath: string,
        servicesRoot: string): ValidationResult =
    ## Validate service directory structure
    ## Args: servicePath - Path of the service directory
    ##       servicesRoot - Absolute path to services directory
    ## Returns: ValidationResult with validation status
    ##
    var serviceDir = absolutePath(servicesRoot / servicePath)
    if not dirExists(serviceDir):
        try:
            serviceDir = utils.resolveServiceDir(servicePath)
        except OSError:
            return ValidationResult(
              valid: false,
              errorMsg: "service directory not found: " & servicePath
            )

    # Validate service directory exists
    if not dirExists(serviceDir):
        return ValidationResult(
          valid: false,
          errorMsg: "service directory not found: " & servicePath
        )

    # Validate service is within services directory
    if not within(servicesRoot, serviceDir):
        return ValidationResult(
          valid: false,
          errorMsg: "service path outside services directory: " & servicePath
        )

    # Return successful validation
    return ValidationResult(
      valid: true,
      srcRel: servicePath,
      dstRel: "",
      errorMsg: ""
    )

proc validatePaths*(srcRel: string, dstRel: string,
        servicesRoot: string): ValidationResult =
    ## Validate source and destination paths
    ## Args: srcRel - Source path relative to services
    ##       dstRel - Destination path relative to services
    ##       servicesRoot - Absolute path to services directory
    ## Returns: ValidationResult with validation status
    ##
    let srcAbs = absolutePath(servicesRoot / srcRel)
    let dstDirAbs = absolutePath(servicesRoot / dstRel)
    let srcName = lastPathPart(srcAbs)
    let dstFinalAbs = absolutePath(dstDirAbs / srcName)

    # Validate source exists and is directory
    if not dirExists(srcAbs):
        return ValidationResult(
          valid: false,
          errorMsg: "source directory not found: " & srcRel
        )

    # Validate paths are within services directory
    if not within(servicesRoot, srcAbs):
        return ValidationResult(
          valid: false,
          errorMsg: "source path outside services directory: " & srcRel
        )

    if not within(servicesRoot, dstDirAbs):
        return ValidationResult(
          valid: false,
          errorMsg: "target path outside services directory: " & dstRel
        )

    # Validate source and target relationship
    if dstFinalAbs == srcAbs:
        return ValidationResult(
          valid: false,
          errorMsg: "source and target are identical: " & srcRel
        )

    if dstFinalAbs.startsWith(srcAbs):
        return ValidationResult(
          valid: false,
          errorMsg: "target cannot be inside source directory"
        )

    # Return successful validation
    return ValidationResult(
      valid: true,
      srcRel: srcRel,
      dstRel: dstRel,
      errorMsg: ""
    )

proc validateCommand*(cmd: string, args: seq[string]): ValidationResult =
    ## Validate copy-service command and arguments
    ## Args: cmd - Command name (should be "copy-service")
    ##       args - List of command arguments
    ## Returns: ValidationResult with validation status and parsed parameters

    # Validate command name
    if cmd != commandName:
        return ValidationResult(
          valid: false,
          errorMsg: "invalid command '" & cmd & "'"
        )

    # Validate argument count
    if args.len != 2:
        return ValidationResult(
          valid: false,
          errorMsg: "expected 2 arguments, got " & $args.len
        )

    # Extract arguments
    let srcRel = args[0]
    let dstRel = args[1]

    # Validate arguments are not empty
    if srcRel == "" or dstRel == "":
        return ValidationResult(
          valid: false,
          errorMsg: "source and target paths cannot be empty"
        )

    # Return successful validation
    return ValidationResult(
      valid: true,
      srcRel: srcRel,
      dstRel: dstRel,
      errorMsg: ""
    )
