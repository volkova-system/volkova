
import os
import helps, handlers, engines

proc executeCommand(command: string, parameters: seq[string]) =

    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       parameters - List of command parameters

    case command
    of "copy-system":
        var valid = handlers.validateCommand(command, parameters)

        if not valid.status:
            stderr.writeLine("copy-system issue, ", valid.issue)
            printUsage()
            quit(1)

        valid = handlers.validatePaths(valid.source, valid.target)

        if not valid.status:
            stderr.writeLine("copy-system issue, ", valid.issue)
            quit(2)

        try:
            valid.target = engines.copySystem(valid.source, valid.target)
        except CatchableError as issue:
            stderr.writeLine("copy-system issue, ", issue.msg)
            quit(2)

        valid = handlers.validateTargetSystemStructure(valid.target)

        if not valid.status:
            stderr.writeLine("copy-system issue, ", valid.issue)
            quit(1)

        echo "copy-system done, target, " & valid.target
        quit(0)

    else:
        stderr.writeLine("copy-system issue, unknown command, '" & command & "'")
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
        stderr.writeLine("copy-system issue, invalid command, '" &
                targetCommand & "'")
        printUsage()
        quit(1)

    if handlers.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)
        quit(0)

    executeCommand(targetCommand, targetParameters)
