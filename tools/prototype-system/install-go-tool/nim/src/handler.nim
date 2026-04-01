# Command handler for install-fiber-go tool

import os
import strutils
import setting
import utils

type
    ValidationResult* = object
        ## Result of parameter validation
        valid*: bool
        serviceName*: string
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

proc validateServiceStructure*(serviceName: string,
        servicesRoot: string): ValidationResult =
    ## Validate service directory structure
    ## Args: serviceName - Name of the service directory
    ##       servicesRoot - Absolute path to services directory
    ## Returns: ValidationResult with validation status
    ##
    var serviceDir = absolutePath(servicesRoot / serviceName)
    if not dirExists(serviceDir):
        try:
            serviceDir = utils.resolveServiceDir(serviceName)
        except OSError:
            return ValidationResult(
              valid: false,
              errorMsg: "Service directory not found: " & serviceName
            )

    let fiberGoDir = absolutePath(serviceDir / "fiber-go")
    let distDir = absolutePath(fiberGoDir / "dist")

    # Validate service directory exists
    if not dirExists(serviceDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Service directory not found: " & serviceName
        )

    # Validate service is within services directory
    if not within(servicesRoot, serviceDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Service path outside services directory: " & serviceName
        )

    # Validate fiber-go directory exists
    if not dirExists(fiberGoDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Fiber-go directory not found in service: " & serviceName & "/fiber-go"
        )

    # Validate dist directory exists
    if not dirExists(distDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Dist directory not found in service: " & serviceName & "/fiber-go/dist"
        )

    # Return successful validation
    return ValidationResult(
      valid: true,
      serviceName: serviceName,
      errorMsg: ""
    )

proc validateCommand*(cmd: string, args: seq[string]): ValidationResult =
    ## Validate install-fiber-go command and arguments
    ## Args: cmd - Command name (should be "install-fiber-go")
    ##       args - List of command arguments
    ## Returns: ValidationResult with validation status and parsed parameters
    ##

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

    # Extract service path
    let servicePathArg = args[0]

    # Validate service path is not empty
    if servicePathArg == "":
        return ValidationResult(
          valid: false,
          errorMsg: "Service path cannot be empty"
        )

    # Validate service path format 'name-system/name-service' or 'name-system/name-go'
    let normalized = servicePathArg.replace("\\", "/")
    let segments = normalized.split("/")
    if segments.len != 2:
        return ValidationResult(
          valid: false,
          errorMsg: "Service path must be in the form 'name-system/name-service': " & servicePathArg
        )

    let systemName = segments[0]
    let serviceNameOnly = segments[1]

    # Validate suffixes
    if not systemName.endsWith("-system"):
        return ValidationResult(
          valid: false,
          errorMsg: "Parent path must end with '-system': " & systemName
        )

    if not serviceNameOnly.endsWith("-service"):
        return ValidationResult(
          valid: false,
          errorMsg: "Service name must end with '-service': " & serviceNameOnly
        )

    # Normalize service path using OS separator
    let servicePath = systemName / serviceNameOnly

    # Return successful validation
    return ValidationResult(
      valid: true,
      serviceName: servicePath,
      errorMsg: ""
    )

proc assertExecutableExists*(execPath: string) =
    ## Assert that the executable file exists, terminate loudly if not
    ## Args: execPath - Absolute path to the executable file
    ##
    if not fileExists(execPath):
        stderr.writeLine(
            "Error: Executable not found: " & execPath
        )
        stderr.writeLine(
            "Run build-fiber-go first to build the service for this platform"
        )
        quit(2)

proc assertInstallDirectoryOnPath*(installDir: string) =
    ## Assert that the install directory is on the system PATH
    ## Args: installDir - Absolute path to the install directory
    ##
    when defined(windows):
        # On Windows, check both system and user PATH
        let systemPath = getEnv("PATH")
        let normalInstall = installDir.toLowerAscii()
        let pathEntries = systemPath.split(';')
        for entry in pathEntries:
            if entry.strip().toLowerAscii() == normalInstall:
                return
        stderr.writeLine(
            "Warning: Install directory not on PATH: " & installDir
        )
        stderr.writeLine(
            "Add it to the system PATH to use the command globally"
        )
    else:
        let systemPath = getEnv("PATH")
        let pathEntries = systemPath.split(':')
        for entry in pathEntries:
            if entry.strip() == installDir:
                return
        stderr.writeLine(
            "Warning: Install directory not on PATH: " & installDir
        )
        stderr.writeLine(
            "Add it to the system PATH to use the command globally"
        )
