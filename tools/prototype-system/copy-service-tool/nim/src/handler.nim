# Command handler for copy-service tool

import os
import setting, help, engine

proc execute*(cmd: string, args: seq[string]) =
  ## Execute copy-service command with arguments
  ## Args: cmd - Command name (should be "copy-service")
  ##       args - List of command arguments

  # Validate command name
  if cmd != commandName:
    stderr.writeLine("Error: Invalid command '" & cmd & "'")
    printUsage()
    quit(1)

  # Validate argument count
  if args.len != 2:
    stderr.writeLine("Error: Expected 2 arguments, got " & $args.len)
    printUsage()
    quit(1)

  # Extract arguments
  let srcRel = args[0]
  let dstRel = args[1]

  # Validate arguments are not empty
  if srcRel == "" or dstRel == "":
    stderr.writeLine("Error: Source and target paths cannot be empty")
    printUsage()
    quit(1)

  # Attempt to copy directory
  try:
    let dstAbs = copyDir(srcRel, dstRel)
    echo "Successfully copied service:"
    echo "  From: ", srcRel
    echo "  To:   ", dstRel
    echo "  Path: ", dstAbs
    quit(0)
  except IOError as e:
    stderr.writeLine("Error: ", e.msg)
    quit(2)
  except OSError as e:
    stderr.writeLine("Error: ", e.msg)
    quit(2)
