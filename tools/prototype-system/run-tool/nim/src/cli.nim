
import os
import helps, handlers, engines

proc executeCommand(command: string, parameters: seq[string]) =

    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       parameters - List of command arguments

    case command
    of "run":
        var valid = handlers.validateCommand(command, parameters)

        if not valid.status:
            stderr.writeLine("run issue, ", valid.issue)
            printUsage()
            quit(1)

        valid = handlers.validateToolFile(valid.target)

        if not valid.status:
            stderr.writeLine("run issue, ", valid.issue)
            quit(1)

        try:
            engines.executeToolFile(valid.target)
        except CatchableError as issue:
            stderr.writeLine("run issue, ", issue.msg)
            quit(2)

        echo "run done, target, " & valid.target
        quit(0)

    else:
        stderr.writeLine("run issue, unknown command, '" & command & "'")
        quit(1)

proc run*() =

    ## Main CLI execution function
    ## Processes command line arguments and delegates to appropriate handlers

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
        stderr.writeLine("run issue, invalid command, '" & command & "'")
        printUsage()
        quit(1)

    if handlers.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)
        quit(0)

    executeCommand(targetCommand, targetParameters)
