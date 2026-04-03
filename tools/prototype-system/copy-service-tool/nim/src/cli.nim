
import os
import helps, handlers, engines

proc executeCommand(command: string, parameters: seq[string]) =

    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       parameters - List of command parameters

    case command
    of "copy-service":
        var valid = handlers.validateCommand(command, parameters)

        if not valid.status:
            stderr.writeLine("issue, ", valid.issue)

            printUsage()

            quit(1)

        valid = handlers.validatePaths(valid.source, valid.target, valid.systems)

        if not valid.status:
            stderr.writeLine("issue, ", valid.issue)

            quit(2)

        try:


            let target = engines.copyService(valid.source, valid.target)



            quit(0)

        except CatchableError as issue:
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

    let command = parameters[0]
    let targetParameters = parameters[1..^1]

    if handlers.checkHelpFlag(command):
        printUsage()

        quit(0)

    if handlers.checkVersionFlag(command):
        printVersion()

        quit(0)

    let targetCommand = handlers.resolveCommand(command)
    if targetCommand == "":
        stderr.writeLine("invalid command, '" & targetCommand & "'")
        printUsage()

        quit(1)

    if handlers.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)

        quit(0)

    executeCommand(targetCommand, targetParameters)
