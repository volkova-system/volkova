# CLI interface for run-tool

import os
import help, handler, engine

proc executeCommand(command: string, args: seq[string]) =

    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       args - List of command arguments

    case command
    of "run":
        let cmdValidation = handler.validateCommand(command, args)

        if not cmdValidation.valid:
            stderr.writeLine("Error: ", cmdValidation.errorMsg)
            printUsage()
            quit(1)

        try:
            engine.executeToolFile(cmdValidation.toolFilePath)
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

    if params.len == 0:
        printUsage()
        quit(1)

    let cmd = params[0]
    let args = params[1..^1]

    if handler.checkHelpFlag(cmd):
        printUsage()
        quit(0)

    if handler.checkVersionFlag(cmd):
        printVersion()
        quit(0)

    let command = handler.resolveCommand(cmd)
    if command == "":
        stderr.writeLine("Error: Invalid command '" & cmd & "'")
        printUsage()
        quit(1)

    if handler.checkCommandHelpFlag(args):
        printCommandHelp(command)
        quit(0)

    executeCommand(command, args)
