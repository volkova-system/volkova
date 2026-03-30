# CLI interface for copy-service tool

import os, strutils
import setting, help, handler

proc checkHelpFlag(flag: string): bool =
  ## Check if argument is a help flag
  ## Args: flag - The flag to check
  ## Returns: Boolean true if it's a help flag
  return flag in ["-h", "--help", "help"]

proc checkCommandHelpFlag(args: seq[string]): bool =
  ## Check if arguments contain command help flag
  ## Args: args - List of arguments to check
  ## Returns: Boolean true if help flag found
  for arg in args:
    if checkHelpFlag(arg):
      return true
  return false

proc resolveCommand(cmdName: string): string =
  ## Resolve command name to internal command
  ## Args: cmdName - Command name from user input
  ## Returns: Resolved command name or empty string if invalid
  let validCommands = @[commandName]

  if cmdName in validCommands:
    return cmdName

  return ""

proc executeCommand(command: string, args: seq[string]) =
  ## Execute the resolved command with arguments
  ## Args: command - The resolved command name
  ##       args - List of command arguments
  case command
  of "copy-service":
    handler.execute(command, args)
  else:
    stderr.writeLine("Error: Unknown command '" & command & "'")
    quit(1)

proc run*() =
  ## Main CLI execution function
  ## Processes command line arguments and delegates to appropriate handlers
  let params = commandLineParams()

  # Check if no arguments provided
  if params.len == 0:
    printUsage()
    quit(1)

  # Get command and arguments
  let cmd = params[0]
  let args = params[1..^1]

  # Handle help requests
  if checkHelpFlag(cmd):
    printUsage()
    quit(0)

  # Validate and execute command
  let command = resolveCommand(cmd)
  if command == "":
    stderr.writeLine("Error: Invalid command '" & cmd & "'")
    printUsage()
    quit(1)

  # Check for command-specific help
  if checkCommandHelpFlag(args):
    printCommandHelp(command)
    quit(0)

  # Execute the command
  executeCommand(command, args)
