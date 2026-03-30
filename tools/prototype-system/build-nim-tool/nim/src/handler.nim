# Command handler for build-nim tool

import os
import setting, help

type
  ValidationResult* = object
    ## Result of parameter validation
    valid*: bool
    toolName*: string
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

proc validateToolStructure*(toolName: string, toolsRoot: string): ValidationResult =
  ## Validate tool directory structure
  ## Args: toolName - Name of the tool directory
  ##       toolsRoot - Absolute path to tools directory
  ## Returns: ValidationResult with validation status
  let toolDir = absolutePath(toolsRoot / toolName)
  let nimDir = absolutePath(toolDir / "nim")
  let srcDir = absolutePath(nimDir / "src")
  let mainFile = absolutePath(srcDir / "main.nim")

  # Validate tool directory exists
  if not dirExists(toolDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Tool directory not found: " & toolName
    )

  # Validate tool is within tools directory
  if not within(toolsRoot, toolDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Tool path outside tools directory: " & toolName
    )

  # Validate nim directory exists
  if not dirExists(nimDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Nim directory not found in tool: " & toolName & "/nim"
    )

  # Validate src directory exists
  if not dirExists(srcDir):
    return ValidationResult(
      valid: false,
      errorMsg: "Source directory not found in tool: " & toolName & "/nim/src"
    )

  # Validate main.nim exists
  if not fileExists(mainFile):
    return ValidationResult(
      valid: false,
      errorMsg: "Main file not found in tool: " & toolName & "/nim/src/main.nim"
    )

  # Return successful validation
  return ValidationResult(
    valid: true,
    toolName: toolName,
    errorMsg: ""
  )

proc validateCommand*(cmd: string, args: seq[string]): ValidationResult =
  ## Validate build-nim command and arguments
  ## Args: cmd - Command name (should be "build-nim")
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

  # Extract tool name
  let toolName = args[0]

  # Validate tool name is not empty
  if toolName == "":
    return ValidationResult(
      valid: false,
      errorMsg: "Tool name cannot be empty"
    )

  # Validate tool name ends with '-tool'
  if not toolName.endsWith("-tool"):
    return ValidationResult(
      valid: false,
      errorMsg: "Tool name must end with '-tool': " & toolName
    )

  # Return successful validation
  return ValidationResult(
    valid: true,
    toolName: toolName,
    errorMsg: ""
  )
