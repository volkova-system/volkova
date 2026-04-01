# Command handler for install-zig tool

import os
import strutils
import setting
import utils

type
    ValidationResult* = object
        ## Result of parameter validation
        valid*: bool
        cliName*: string
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

proc within(base: string, path: string): bool =
    ## Check if path is within base directory
    ## Args: base - Base directory path
    ##       path - Path to check
    ## Returns: Boolean true if path is within base
    let normalBase = absolutePath(base)
    let normalPath = absolutePath(path)
    return normalPath.startsWith(normalBase)

proc validateCliStructure*(cliName: string,
        interfacesRoot: string): ValidationResult =
    ## Validate CLI directory structure
    ## Args: cliName - Name of the CLI directory
    ##       interfacesRoot - Absolute path to interfaces directory
    ## Returns: ValidationResult with validation status
    var cliDir = absolutePath(interfacesRoot / cliName)
    if not dirExists(cliDir):
        try:
            cliDir = utils.resolveCliDir(cliName)
        except OSError:
            return ValidationResult(
              valid: false,
              errorMsg: "CLI directory not found: " & cliName
            )
    let zigDir = absolutePath(cliDir / "zig")
    let distDir = absolutePath(zigDir / "dist")

    # Validate CLI directory exists
    if not dirExists(cliDir):
        return ValidationResult(
          valid: false,
          errorMsg: "CLI directory not found: " & cliName
        )

    # Validate CLI is within interfaces directory
    if not within(interfacesRoot, cliDir):
        return ValidationResult(
          valid: false,
          errorMsg: "CLI path outside interfaces directory: " & cliName
        )

    # Validate zig directory exists
    if not dirExists(zigDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Zig directory not found in CLI: " & cliName & "/zig"
        )

    # Validate dist directory exists
    if not dirExists(distDir):
        return ValidationResult(
          valid: false,
          errorMsg: "Dist directory not found in CLI: " & cliName & "/zig/dist"
        )

    # Return successful validation
    return ValidationResult(
      valid: true,
      cliName: cliName,
      errorMsg: ""
    )

proc validateCommand*(cmd: string, args: seq[string]): ValidationResult =
    ## Validate install-zig command and arguments
    ## Args: cmd - Command name (should be "install-zig")
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

    # Extract CLI path
    let cliPathArg = args[0]

    # Validate CLI path is not empty
    if cliPathArg == "":
        return ValidationResult(
          valid: false,
          errorMsg: "CLI path cannot be empty"
        )

    # Validate CLI path format 'name-system/name-cli'
    let normalized = cliPathArg.replace("\\", "/")
    let segments = normalized.split("/")
    if segments.len != 2:
        return ValidationResult(
          valid: false,
          errorMsg: "CLI path must be in the form 'name-system/name-cli': " & cliPathArg
        )

    let systemName = segments[0]
    let cliNameOnly = segments[1]

    # Validate suffixes
    if not systemName.endsWith("-system"):
        return ValidationResult(
          valid: false,
          errorMsg: "Parent path must end with '-system': " & systemName
        )

    if not cliNameOnly.endsWith("-cli"):
        return ValidationResult(
          valid: false,
          errorMsg: "CLI name must end with '-cli': " & cliNameOnly
        )

    # Normalize CLI path using OS separator
    let cliPath = systemName / cliNameOnly

    # Return successful validation
    return ValidationResult(
      valid: true,
      cliName: cliPath,
      errorMsg: ""
    )

proc assertExecutableExists*(execPath: string) =
    ## Assert that the executable file exists, terminate loudly if not
    ## Args: execPath - Absolute path to the executable file
    if not fileExists(execPath):
        stderr.writeLine(
            "Error: Executable not found: " & execPath
        )
        stderr.writeLine(
            "Run build-zig first to build the CLI for this platform"
        )
        quit(2)

proc assertInstallDirectoryOnPath*(installDir: string) =
    ## Assert that the install directory is on the system PATH
    ## Args: installDir - Absolute path to the install directory
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
