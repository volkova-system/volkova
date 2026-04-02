# CLI interface for copy-service tool

import os
import help, handler, engine, utils

proc executeCommand(command: string, parameters: seq[string]) =
    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       parameters - List of command parameters

    case command
    of "copy-service":
        let cmdValidation = handler.validateCommand(command, parameters)

        if not cmdValidation.status:
            stderr.writeLine("Error: ", cmdValidation.issue)
            printUsage()
            quit(1)

        # Get services root and validate paths
        try:
            let servicesRootPath = utils.getServicesRootPath()
            let systemsRootPath = utils.getSystemsRootPath()

            let pathValidation = handler.validatePaths(
                    cmdValidation.source,
                    cmdValidation.target,
                    servicesRootPath
                )

            if not pathValidation.status:
                stderr.writeLine("Error: ", pathValidation.issue)
                quit(2)

            # Execute using engine with validated parameters
            let dstAbs = engine.copyDir(cmdValidation.source, cmdValidation.target)
            let toRel = cmdValidation.source & "/" & lastPathPart(cmdValidation.source)

            echo "Successfully copied service:"
            echo "  From: ", cmdValidation.source
            echo "  To:   ", toRel
            echo "  Path: ", dstAbs

            quit(0)

        except IOError as issue:
            stderr.writeLine("issue, ", issue.msg)
            quit(2)

        except OSError as issue:
            stderr.writeLine("issue, ", issue.msg)
            quit(2)
    else:
        stderr.writeLine("unknown command, '" & command & "'")
        quit(1)

proc run*() =
    let parameters = commandLineParams()

    if parameters.len == 0:
        printUsage()
        quit(1)

    # Get command and arguments
    let command = parameters[0]
    let targetParameters = parameters[1..^1]

    if handler.checkHelpFlag(command):
        printUsage()
        quit(0)

    if handler.checkVersionFlag(command):
        printVersion()
        quit(0)

    let targetCommand = handler.resolveCommand(command)
    if targetCommand == "":
        stderr.writeLine("invalid command, '" & targetCommand & "'")
        printUsage()
        quit(1)

    if handler.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)
        quit(0)

    executeCommand(targetCommand, targetParameters)
