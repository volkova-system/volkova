# Command handler for install-nim tool

import os
import setting

type
  ValidationResult* = object
    ## Result of parameter validation
    valid*: bool
    toolDirectory*: string
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
  ## Validate install-nim command and arguments
  ## Args: cmd - Command name (should be "install-nim")
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

  # Extract tool directory
  let toolDirectory = args[0]

  # Validate tool directory is not empty
  if toolDirectory == "":
    return ValidationResult(
      valid: false,
      errorMsg: "Tool directory cannot be empty"
    )

  # Return successful validation
  return ValidationResult(
    valid: true,
    toolDirectory: absolutePath(toolDirectory),
    errorMsg: ""
  )

proc validateToolDirectory*(toolDirectory: string): ValidationResult =
  ## Validate that the tool directory exists and has required structure
  ## Args: toolDirectory - Absolute path to the tool directory
  ## Returns: ValidationResult with validation status
  let nimDir = absolutePath(toolDirectory / nimDirectory)
  let distDir = absolutePath(nimDir / distDirectory)

  # Validate tool directory exists
  if not dirExists(toolDirectory):
    return ValidationResult(
      valid: false,
      errorMsg: "Tool directory not found: " & toolDirectory
    )

  # Validate nim directory exists
  if not dirExists(nimDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Nim directory not found: " & nimDir
    )

  # Validate dist directory exists
  if not dirExists(distDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Dist directory not found: " & distDir
    )

  # Return successful validation
  return ValidationResult(
    valid: true,
    toolDirectory: toolDirectory,
    errorMsg: ""
  )
