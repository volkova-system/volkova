# CLI interface for copy-service tool

import os
import help, handler, engine, utils

proc executeCommand(command: string, args: seq[string]) =
    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       args - List of command arguments
    case command
    of "copy-service":
        # Validate command and basic parameters
        let cmdValidation = handler.validateCommand(command, args)

        if not cmdValidation.valid:
            stderr.writeLine("Error: ", cmdValidation.errorMsg)
            printUsage()
            quit(1)

        # Get services root and validate paths
        try:
            let servicesRoot = utils.servicesRoot()
            let pathValidation = handler.validatePaths(cmdValidation.srcRel,
                    cmdValidation.dstRel, servicesRoot)

            if not pathValidation.valid:
                stderr.writeLine("Error: ", pathValidation.errorMsg)
                quit(2)

            # Execute using engine with validated parameters
            let dstAbs = engine.copyDir(cmdValidation.srcRel,
                    cmdValidation.dstRel)
            let toRel = cmdValidation.dstRel & "/" & lastPathPart(
                    cmdValidation.srcRel)

            echo "Successfully copied service:"
            echo "  From: ", cmdValidation.srcRel
            echo "  To:   ", toRel
            echo "  Path: ", dstAbs

            quit(0)

        except IOError as e:
            stderr.writeLine("Error: ", e.msg)
            quit(2)

        except OSError as e:
            stderr.writeLine("Error: ", e.msg)
            quit(2)
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
    if handler.checkHelpFlag(cmd):
        printUsage()
        quit(0)

    # Handle version requests
    if handler.checkVersionFlag(cmd):
        printVersion()
        quit(0)

    # Validate and execute command
    let command = handler.resolveCommand(cmd)
    if command == "":
        stderr.writeLine("Error: Invalid command '" & cmd & "'")
        printUsage()
        quit(1)

    # Check for command-specific help
    if handler.checkCommandHelpFlag(args):
        printCommandHelp(command)
        quit(0)

    # Execute the command
    executeCommand(command, args)
