import os
import engines, handlers, helps, models

proc executeCommand(command: string, parameters: seq[string]) =
    case command
    of "build-zig":
        var session = ToolSession(command: command, parameters: parameters)

        session = handlers.validateCommand(session)
        if not session.status:
            stderr.writeLine("build-zig issue, ", session.issue)
            printUsage()
            quit(1)

        session = handlers.validateInterfaceStructure(session)
        if not session.status:
            stderr.writeLine("build-zig issue, ", session.issue)
            quit(1)

        try:
            session = engines.buildInterface(engines.formatInterfaceSource(session))
        except CatchableError as issue:
            stderr.writeLine("build-zig issue, ", issue.msg)
            quit(2)

        session = handlers.validateExecutable(session)
        if not session.status:
            stderr.writeLine("build-zig issue, " & session.issue)
            quit(1)

        echo "build-zig done, target, " & session.executable
        quit(0)

    else:
        stderr.writeLine("build-zig issue, unknown command, '" & command & "'")
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
        stderr.writeLine("build-zig issue, invalid command, '" & command & "'")
        printUsage()
        quit(1)

    if handlers.checkCommandHelpFlag(targetParameters):
        printCommandHelp(targetCommand)
        quit(0)

    executeCommand(targetCommand, targetParameters)
