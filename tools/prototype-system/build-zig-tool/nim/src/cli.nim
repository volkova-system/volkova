# CLI interface for build-zig tool

import os
import help, handler, engine, utils

proc executeCommand(command: string, args: seq[string]) =
    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       args - List of command arguments
    case command
    of "build-zig":
        # Validate command and basic parameters
        let cmdValidation = handler.validateCommand(command, args)

        if not cmdValidation.valid:
            stderr.writeLine("Error: ", cmdValidation.errorMsg)
            printUsage()
            quit(1)

        # Get interfaces root and validate CLI structure
        try:
            let interfacesRoot = utils.interfacesRoot()
            let structureValidation = handler.validateCliStructure(
                    cmdValidation.cliName, interfacesRoot)

            if not structureValidation.valid:
                stderr.writeLine("Error: ", structureValidation.errorMsg)
                quit(2)

            # Execute build using engine with validated parameters
            let execPath = engine.buildCli(cmdValidation.cliName)
            let platform = engine.getCurrentPlatform()
            echo "Successfully built CLI:"
            echo "  CLI: ", cmdValidation.cliName
            echo "  Platform: ", platform
            echo "  Executable: ", execPath
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
