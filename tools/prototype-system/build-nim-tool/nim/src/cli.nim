
import os
import engines, handlers, helps, models

proc executeCommand(command: string, parameters: seq[string]) =

    ## Execute the resolved command with arguments
    ## Args: command - The resolved command name
    ##       parameters - List of command parameters

    case command
    of "build-nim":
        var session = handlers.validateCommand(ToolSession(
            command: command,
            parameters: parameters
        ))

        if not session.status:
            stderr.writeLine("build-nim issue, ", session.issue)
            printUsage()
            quit(1)

        session = handlers.validateToolStructure(session)

        if not session.status:
            stderr.writeLine("build-nim issue, ", session.issue)
            quit(1)

        try:
            session = engines.buildTool(session)
        except CatchableError as issue:
            stderr.writeLine("build-nim issue, ", issue.msg)
            quit(2)

        if not fileExists(session.tool):
            stderr.writeLine(
                "build-nim issue, executable file not found, " & session.tool
            )
            quit(1)

        echo "build-nim done, target, " & session.executable
        quit(0)

    else:
        stderr.writeLine("build-nim issue, unknown command, '" & command & "'")
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
        stderr.writeLine("build-nim issue, invalid command, '" & command & "'")
        printUsage()
        quit(1)

    if handlers.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)
        quit(0)

    executeCommand(targetCommand, targetParameters)
